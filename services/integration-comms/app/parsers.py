"""
Parsers for what lab devices (via the Open Integration Engine) send us. Three families, one normalised result:

  * HL7 v2   - ORU^R01 result messages (pipe-delimited, MLLP framing tolerated)
  * HL7 v3   - XML observation messages (a pragmatic subset: observation/code/value/interpretationCode/referenceRange)
  * FHIR R4  - Bundle (or a single Observation) as JSON, with Observation.specimen / Specimen.accessionIdentifier

Everything ends up as a ParsedMessage whose analytes map 1:1 to the AnalyzerResultReceived event the Laboratory service
consumes. Nothing here touches the database or the network, so it is easy to test.
"""
from __future__ import annotations

import hashlib
import json
import re
import xml.etree.ElementTree as ET
from dataclasses import dataclass, field
from datetime import datetime, timezone
from decimal import Decimal, InvalidOperation
from typing import Optional
from zoneinfo import ZoneInfo

from .config import settings

CRITICAL_FLAGS = {"HH", "LL", "AA", "CC", "C", "CRIT", "CRITICAL"}


class ParseError(ValueError):
    """The message is not something we can turn into results (reported back to the device/engine as a NACK)."""


@dataclass
class Analyte:
    parameter_code: str
    machine_test_code: Optional[str] = None
    parameter_name: Optional[str] = None
    value_numeric: Optional[Decimal] = None
    value_text: Optional[str] = None
    unit: Optional[str] = None
    reference_range_text: Optional[str] = None
    abnormal_flag: Optional[str] = None
    is_critical: bool = False

    def to_json(self) -> dict:
        return {
            "parameterCode": self.parameter_code, "machineTestCode": self.machine_test_code or self.parameter_code,
            "parameterName": self.parameter_name,
            "valueNumeric": float(self.value_numeric) if self.value_numeric is not None else None,
            "valueText": self.value_text, "unit": self.unit, "referenceRangeText": self.reference_range_text,
            "abnormalFlag": self.abnormal_flag, "isCritical": self.is_critical,
        }


@dataclass
class ParsedMessage:
    format: str                       # HL7V2 | HL7V3 | FHIR
    message_id: str
    message_type: str
    sample_barcode: str
    analyzer_code: Optional[str]
    resulted_at: Optional[datetime]
    analytes: list = field(default_factory=list)

    def to_event_payload(self, message_log_id: Optional[int], analyzer_override: Optional[str] = None) -> dict:
        """Body of the AnalyzerResultReceived event (camelCase, matches Hims.Common AnalyzerResultReceivedPayload)."""
        return {
            "sampleBarcode": self.sample_barcode, "analyzerCode": analyzer_override or self.analyzer_code,
            "sourceMessageId": self.message_id, "messageType": self.message_type,
            "resultedAt": self.resulted_at.astimezone(timezone.utc).isoformat().replace("+00:00", "Z") if self.resulted_at else None,
            "messageLogId": message_log_id, "analytes": [a.to_json() for a in self.analytes],
        }


# --------------------------------------------------------------------------------------------- helpers

def _num(text: Optional[str]) -> Optional[Decimal]:
    if text is None:
        return None
    t = text.strip().replace(",", "")
    if not t:
        return None
    try:
        return Decimal(t)
    except InvalidOperation:
        return None


def _is_critical(flag: Optional[str]) -> bool:
    return bool(flag) and flag.strip().upper() in CRITICAL_FLAGS


def _device_tz() -> ZoneInfo:
    try:
        return ZoneInfo(settings.device_timezone)
    except Exception:
        return ZoneInfo("UTC")


def parse_hl7_timestamp(value: Optional[str]) -> Optional[datetime]:
    """HL7 TS/DTM: YYYY[MM[DD[HH[MM[SS[.S+]]]]]][+/-ZZZZ]. No offset = the configured device time zone. Returns aware datetime."""
    if not value:
        return None
    m = re.fullmatch(r"(\d{4})(\d{2})?(\d{2})?(\d{2})?(\d{2})?(\d{2})?(?:\.\d+)?([+-]\d{4})?", value.strip())
    if not m:
        return None
    y, mo, d, h, mi, s, off = m.groups()
    try:
        dt = datetime(int(y), int(mo or 1), int(d or 1), int(h or 0), int(mi or 0), int(s or 0))
    except ValueError:
        return None
    if off:
        sign = 1 if off[0] == "+" else -1
        from datetime import timedelta
        tz = timezone(sign * timedelta(hours=int(off[1:3]), minutes=int(off[3:5])))
        return dt.replace(tzinfo=tz)
    return dt.replace(tzinfo=_device_tz())


def _parse_iso(value: Optional[str]) -> Optional[datetime]:
    if not value:
        return None
    try:
        dt = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None
    return dt if dt.tzinfo else dt.replace(tzinfo=_device_tz())


def detect_format(raw: str) -> str:
    t = raw.lstrip("\x0b\ufeff \t\r\n")
    if t.startswith("MSH"):
        return "HL7V2"
    if t.startswith("<"):
        return "HL7V3"
    if t.startswith("{") or t.startswith("["):
        return "FHIR"
    raise ParseError("Unrecognised message format (expected HL7 v2 'MSH|...', HL7 v3 XML or FHIR JSON)")


def parse_message(raw: str) -> ParsedMessage:
    fmt = detect_format(raw)
    return {"HL7V2": parse_hl7v2, "HL7V3": parse_hl7v3, "FHIR": parse_fhir}[fmt](raw)


# --------------------------------------------------------------------------------------------- HL7 v2

def _components(field_value: str, comp_sep: str) -> list:
    return field_value.split(comp_sep) if field_value else []


def parse_hl7v2(raw: str) -> ParsedMessage:
    text = raw.strip("\x0b\x1c\r\n \ufeff")
    segments = [s for s in re.split(r"[\r\n]+", text) if s.strip()]
    if not segments or not segments[0].startswith("MSH") or len(segments[0]) < 8:
        raise ParseError("Not an HL7 v2 message: missing MSH segment")

    fs = segments[0][3]
    comp = segments[0][4]
    rep = segments[0][5]

    def parts(seg: str) -> list:
        p = seg.split(fs)
        # MSH-1 is the field separator itself, so MSH-n sits at index n-1; every other segment has SEG-n at index n.
        return p if not seg.startswith("MSH") else ["MSH", fs] + p[1:]

    def get(p: list, n: int) -> str:
        return p[n] if n < len(p) else ""

    def first_comp(v: str, n: int = 0) -> str:
        c = _components(v.split(rep)[0], comp)
        return c[n].split("&")[0].strip() if n < len(c) else ""

    by_type: dict = {}
    for s in segments:
        by_type.setdefault(s[:3], []).append(parts(s))

    msh = by_type["MSH"][0]
    message_type = get(msh, 9).replace(comp, "^")
    if not message_type.upper().startswith("ORU"):
        raise ParseError(f"Unsupported HL7 message type '{message_type}' (expected ORU^R01)")
    message_id = get(msh, 10).strip()
    if not message_id:
        raise ParseError("MSH-10 (message control id) is empty")
    analyzer = first_comp(get(msh, 3)) or None

    # Specimen / sample barcode: SPM-2, then OBR-3, OBR-2, ORC-3, ORC-2
    barcode = ""
    candidates = []
    if "SPM" in by_type:
        candidates.append(first_comp(get(by_type["SPM"][0], 2)))
    if "OBR" in by_type:
        candidates += [first_comp(get(by_type["OBR"][0], 3)), first_comp(get(by_type["OBR"][0], 2))]
    if "ORC" in by_type:
        candidates += [first_comp(get(by_type["ORC"][0], 3)), first_comp(get(by_type["ORC"][0], 2))]
    for c in candidates:
        if c:
            barcode = c
            break
    if not barcode:
        raise ParseError("No sample barcode found (looked in SPM-2, OBR-3, OBR-2, ORC-3, ORC-2)")

    obr_time = parse_hl7_timestamp(first_comp(get(by_type["OBR"][0], 22))) if "OBR" in by_type else None
    msg_time = parse_hl7_timestamp(get(msh, 7))

    analytes = []
    for obx in by_type.get("OBX", []):
        status = get(obx, 11).strip().upper()
        if status == "X":
            continue                                   # deleted observation
        ident = _components(get(obx, 3).split(rep)[0], comp)
        code = (ident[0] if ident else "").strip()
        if not code:
            continue
        name = ident[1].strip() if len(ident) > 1 else None
        vtype = get(obx, 2).strip().upper()
        raw_value = get(obx, 5).split(rep)[0]
        numeric = None
        text_value = None
        if vtype in ("NM", ""):
            numeric = _num(raw_value)
            if numeric is None and raw_value.strip():
                text_value = raw_value.strip()
        elif vtype == "SN":                           # structured numeric: comparator ^ number [^ separator ^ number2]
            sn = _components(raw_value, comp)
            numeric = _num(sn[1]) if len(sn) > 1 else _num(raw_value)
            comparator = sn[0].strip() if sn else ""
            text_value = f"{comparator}{sn[1]}" if comparator in ("<", ">", "<=", ">=") and len(sn) > 1 else None
        elif vtype in ("CE", "CWE", "CNE"):
            c = _components(raw_value, comp)
            text_value = (c[1] if len(c) > 1 and c[1] else c[0] if c else "").strip() or None
        else:                                          # ST, TX, FT, ...
            text_value = raw_value.strip() or None
        units = _components(get(obx, 6), comp)
        unit = next((u.strip() for u in units if u.strip()), None)
        flag = get(obx, 8).split(rep)[0].strip() or None
        when = parse_hl7_timestamp(get(obx, 14)) or obr_time or msg_time
        analytes.append(Analyte(parameter_code=code, machine_test_code=code, parameter_name=name, value_numeric=numeric,
                                value_text=text_value, unit=unit, reference_range_text=get(obx, 7).strip() or None,
                                abnormal_flag=flag, is_critical=_is_critical(flag)))
        if when and (msg_time is None or when > msg_time):
            msg_time = when
    if not analytes:
        raise ParseError("The message has no usable OBX (observation) segments")

    return ParsedMessage("HL7V2", message_id, message_type, barcode, analyzer, obr_time or msg_time, analytes)


def build_hl7v2_ack(raw: str, ok: bool, error: str = "") -> str:
    """Minimal HL7 v2 ACK so an engine/device that expects one gets AA (accepted) or AE (error)."""
    try:
        text = raw.strip("\x0b\x1c\r\n ")
        msh = re.split(r"[\r\n]+", text)[0].split("|")
        sending_app, sending_fac, control_id = msh[2], msh[3], msh[9]
    except Exception:
        sending_app = sending_fac = control_id = ""
    now = datetime.now(timezone.utc).strftime("%Y%m%d%H%M%S")
    code = "AA" if ok else "AE"
    lines = [f"MSH|^~\\&|HIMS-HUB|HIMS|{sending_app}|{sending_fac}|{now}||ACK|ACK{now}|P|2.5", f"MSA|{code}|{control_id}" + ("" if ok else f"|{error[:80].replace('|', ' ')}")]
    return "\r".join(lines) + "\r"


# --------------------------------------------------------------------------------------------- HL7 v3

def _local(tag: str) -> str:
    return tag.split("}")[-1]


def _kids(el: ET.Element, name: str) -> list:
    return [c for c in el if _local(c.tag) == name]


def _first(el: ET.Element, *path: str) -> Optional[ET.Element]:
    cur = [el]
    for name in path:
        nxt = []
        for e in cur:
            nxt += _kids(e, name)
        cur = nxt
        if not cur:
            return None
    return cur[0]


def _descendants(el: ET.Element, name: str) -> list:
    return [e for e in el.iter() if _local(e.tag) == name]


XSI_TYPE = "{http://www.w3.org/2001/XMLSchema-instance}type"


def parse_hl7v3(raw: str) -> ParsedMessage:
    try:
        root = ET.fromstring(raw.strip().lstrip("\ufeff"))
    except ET.ParseError as e:
        raise ParseError(f"Invalid HL7 v3 XML: {e}") from e

    id_el = _first(root, "id")
    message_id = ((id_el.get("extension") or id_el.get("root")) if id_el is not None else None) or \
        "v3-" + hashlib.sha1(raw.encode()).hexdigest()[:16]
    message_type = _local(root.tag)

    # Sample barcode: specimen identifier, else the placer order id
    barcode = ""
    for spec in _descendants(root, "specimen") + _descendants(root, "specimenRole"):
        for i in _descendants(spec, "id"):
            barcode = (i.get("extension") or "").strip()
            if barcode:
                break
        if barcode:
            break
    if not barcode:
        for order in _descendants(root, "placerOrder"):
            i = _first(order, "id")
            if i is not None and i.get("extension"):
                barcode = i.get("extension", "").strip()
                break
    if not barcode:
        raise ParseError("No sample barcode found in the HL7 v3 message (specimen/id or placerOrder/id @extension)")

    device = None
    for d in _descendants(root, "device") + _descendants(root, "assignedDevice"):
        i = _first(d, "id")
        n = _first(d, "name")
        device = (i.get("extension") if i is not None else None) or (n.text.strip() if n is not None and n.text else None)
        if device:
            break

    analytes = []
    latest = None
    for obs in _descendants(root, "observation") + _descendants(root, "observationEvent"):
        code_el = _first(obs, "code")
        value_el = _first(obs, "value")
        if code_el is None or value_el is None or not code_el.get("code"):
            continue
        vtype = (value_el.get(XSI_TYPE) or "").split(":")[-1].upper()
        numeric, text_value, unit = None, None, value_el.get("unit")
        if vtype == "PQ" or (not vtype and value_el.get("value") is not None):
            numeric = _num(value_el.get("value"))
            if numeric is None and value_el.get("value"):
                text_value = value_el.get("value")
        elif vtype in ("CD", "CE", "CV"):
            text_value = value_el.get("displayName") or value_el.get("code")
        else:
            text_value = (value_el.text or value_el.get("value") or "").strip() or None
        interp = _first(obs, "interpretationCode")
        flag = interp.get("code") if interp is not None else None
        rng = _first(obs, "referenceRange", "observationRange")
        range_text = None
        if rng is not None:
            t = _first(rng, "text")
            if t is not None and t.text:
                range_text = t.text.strip()
            else:
                v = _first(rng, "value")
                low = _first(v, "low") if v is not None else None
                high = _first(v, "high") if v is not None else None
                if low is not None or high is not None:
                    range_text = f"{low.get('value') if low is not None else ''} - {high.get('value') if high is not None else ''}".strip(" -")
        et = _first(obs, "effectiveTime")
        when = parse_hl7_timestamp(et.get("value")) if et is not None and et.get("value") else None
        if when and (latest is None or when > latest):
            latest = when
        analytes.append(Analyte(parameter_code=code_el.get("code", ""), machine_test_code=code_el.get("code"),
                                parameter_name=code_el.get("displayName"), value_numeric=numeric, value_text=text_value, unit=unit,
                                reference_range_text=range_text, abnormal_flag=flag, is_critical=_is_critical(flag)))
    if not analytes:
        raise ParseError("The HL7 v3 message has no observations with a code and a value")
    return ParsedMessage("HL7V3", message_id, message_type, barcode, device, latest, analytes)


# --------------------------------------------------------------------------------------------- FHIR

def parse_fhir(raw: str) -> ParsedMessage:
    try:
        doc = json.loads(raw)
    except json.JSONDecodeError as e:
        raise ParseError(f"Invalid FHIR JSON: {e}") from e
    if not isinstance(doc, dict) or "resourceType" not in doc:
        raise ParseError("FHIR message must be a JSON resource with resourceType")

    resources = [e.get("resource", {}) for e in doc.get("entry", [])] if doc["resourceType"] == "Bundle" else [doc]
    by_key: dict = {}
    for entry in (doc.get("entry", []) if doc["resourceType"] == "Bundle" else []):
        r = entry.get("resource", {})
        if r.get("id"):
            by_key[f"{r.get('resourceType')}/{r['id']}"] = r
        if entry.get("fullUrl"):
            by_key[entry["fullUrl"]] = r
    observations = [r for r in resources if r.get("resourceType") == "Observation"]
    if not observations:
        raise ParseError("The FHIR message contains no Observation resources")

    def specimen_barcode(obs: dict) -> str:
        spec = obs.get("specimen") or {}
        if spec.get("identifier", {}).get("value"):
            return spec["identifier"]["value"]
        ref = spec.get("reference")
        if ref and ref in by_key:
            s = by_key[ref]
            return (s.get("accessionIdentifier") or {}).get("value") or ((s.get("identifier") or [{}])[0]).get("value") or ""
        for ident in obs.get("identifier", []):
            if any(k in (ident.get("system") or "").lower() for k in ("barcode", "sample", "specimen", "accession")):
                return ident.get("value", "")
        return ""

    def device_code(obs: dict) -> Optional[str]:
        dev = obs.get("device") or {}
        if dev.get("identifier", {}).get("value"):
            return dev["identifier"]["value"]
        if dev.get("reference") in by_key:
            d = by_key[dev["reference"]]
            return ((d.get("identifier") or [{}])[0]).get("value") or (d.get("deviceName") or [{}])[0].get("name")
        return dev.get("display")

    barcode = next((b for b in (specimen_barcode(o) for o in observations) if b), "")
    if not barcode:
        raise ParseError("No sample barcode found (Observation.specimen.identifier / Specimen.accessionIdentifier)")
    analyzer = next((d for d in (device_code(o) for o in observations) if d), None)

    analytes = []
    latest = None
    for o in observations:
        coding = ((o.get("code") or {}).get("coding") or [{}])[0]
        code = coding.get("code") or ""
        if not code:
            continue
        numeric, text_value, unit = None, None, None
        if "valueQuantity" in o:
            q = o["valueQuantity"]
            numeric = _num(str(q.get("value"))) if q.get("value") is not None else None
            unit = q.get("unit") or q.get("code")
        elif "valueInteger" in o:
            numeric = Decimal(o["valueInteger"])
        elif "valueString" in o:
            text_value = o["valueString"]
        elif "valueCodeableConcept" in o:
            vc = o["valueCodeableConcept"]
            text_value = vc.get("text") or ((vc.get("coding") or [{}])[0]).get("display")
        rr = (o.get("referenceRange") or [{}])[0]
        range_text = rr.get("text")
        if not range_text and (rr.get("low") or rr.get("high")):
            range_text = f"{(rr.get('low') or {}).get('value', '')} - {(rr.get('high') or {}).get('value', '')}".strip(" -")
        flag = (((o.get("interpretation") or [{}])[0].get("coding") or [{}])[0]).get("code")
        when = _parse_iso(o.get("effectiveDateTime") or o.get("issued"))
        if when and (latest is None or when > latest):
            latest = when
        analytes.append(Analyte(parameter_code=code, machine_test_code=code, parameter_name=coding.get("display") or (o.get("code") or {}).get("text"),
                                value_numeric=numeric, value_text=text_value, unit=unit, reference_range_text=range_text,
                                abnormal_flag=flag, is_critical=_is_critical(flag)))
    if not analytes:
        raise ParseError("No Observation with a code was found")
    ident = doc.get("identifier")
    message_id = doc.get("id") or (ident.get("value") if isinstance(ident, dict) else None) or "fhir-" + hashlib.sha1(raw.encode()).hexdigest()[:16]
    return ParsedMessage("FHIR", str(message_id), f"FHIR {doc['resourceType']}", barcode, analyzer, latest, analytes)

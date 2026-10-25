"""
Device simulator: builds realistic HL7 v2 / HL7 v3 / FHIR result messages for the tests on a sample, so the whole device -> hub ->
RabbitMQ -> Laboratory -> Clinical Care -> FHIR loop can be demonstrated without a physical analyzer. Codes match database/seed.
"""
import random
import uuid
from datetime import datetime
from typing import Optional
from xml.sax.saxutils import escape
from zoneinfo import ZoneInfo

from .config import settings

# service code -> (panel name, [(loinc, name, low, high, unit, decimals)])
PANELS = {
    "LAB-CBC": ("CBC panel", [("6690-2", "WBC (Total Leucocyte Count)", 4.0, 11.0, "10*3/uL", 1), ("789-8", "RBC Count", 4.2, 5.9, "10*6/uL", 2),
                              ("718-7", "Haemoglobin", 13.0, 17.0, "g/dL", 1), ("4544-3", "Haematocrit (PCV)", 38.0, 50.0, "%", 1),
                              ("777-3", "Platelet Count", 150, 410, "10*3/uL", 0)]),
    "LAB-FBS": ("Fasting glucose", [("1558-6", "Fasting Glucose", 70, 100, "mg/dL", 0)]),
    "LAB-LIPID": ("Lipid panel", [("2093-3", "Total Cholesterol", 125, 200, "mg/dL", 0), ("2085-9", "HDL Cholesterol", 40, 80, "mg/dL", 0),
                                  ("13457-7", "LDL Cholesterol (calculated)", 60, 130, "mg/dL", 0), ("2571-8", "Triglycerides", 50, 150, "mg/dL", 0)]),
    "LAB-HBA1C": ("HbA1c", [("4548-4", "HbA1c", 4.0, 5.6, "%", 1)]),
}


def _analytes(service_codes: list, abnormal: bool, critical: bool) -> list:
    rows, first = [], True
    for code in service_codes:
        if code not in PANELS:
            raise ValueError(f"No simulator panel for service code '{code}'. Known: {', '.join(PANELS)}")
        for loinc, name, low, high, unit, dp in PANELS[code][1]:
            value, flag = random.uniform(low + (high - low) * 0.2, high - (high - low) * 0.2), "N"
            if first and critical:
                value, flag = high * 2.2, "HH"
            elif first and abnormal:
                value, flag = high * 1.3, "H"
            first = False
            rows.append({"code": loinc, "name": name, "value": round(value, dp) if dp else int(round(value)), "unit": unit,
                         "range": f"{low}-{high}", "low": low, "high": high, "flag": flag})
    return rows


def _now():
    return datetime.now(ZoneInfo(settings.device_timezone))


def build_message(fmt: str, sample_barcode: str, analyzer_code: str, service_codes: list, abnormal: bool = False, critical: bool = False) -> tuple:
    """Returns (raw_message, message_id)."""
    fmt = fmt.upper()
    analytes = _analytes(service_codes, abnormal, critical)
    message_id = f"SIM-{uuid.uuid4().hex[:12]}"
    now = _now()
    if fmt == "HL7V2":
        ts = now.strftime("%Y%m%d%H%M%S%z")
        panel = PANELS[service_codes[0]][0]
        lines = [f"MSH|^~\\&|{analyzer_code}|LAB|HIMS|DRR|{ts}||ORU^R01|{message_id}|P|2.5.1",
                 f"OBR|1||{sample_barcode}|PANEL^{panel}|||{ts}"]
        for i, a in enumerate(analytes, 1):
            lines.append(f"OBX|{i}|NM|{a['code']}^{a['name']}^LN||{a['value']}|{a['unit']}|{a['range']}|{a['flag']}|||F|||{ts}")
        return "\r".join(lines) + "\r", message_id
    if fmt == "HL7V3":
        ts = now.strftime("%Y%m%d%H%M%S")
        obs = "".join(
            f'<component><observationEvent><code code="{a["code"]}" displayName="{escape(a["name"])}"/><effectiveTime value="{ts}"/>'
            f'<value xsi:type="PQ" value="{a["value"]}" unit="{escape(a["unit"])}"/><interpretationCode code="{a["flag"]}"/>'
            f'<specimen><specimenRole><id extension="{sample_barcode}"/></specimenRole></specimen>'
            f'<referenceRange><observationRange><value><low value="{a["low"]}"/><high value="{a["high"]}"/></value></observationRange></referenceRange>'
            f'</observationEvent></component>' for a in analytes)
        xml = (f'<?xml version="1.0" encoding="UTF-8"?><POLB_IN224100UV01 xmlns="urn:hl7-org:v3" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'
               f'<id root="2.16.840.1.113883.19.1122.7" extension="{message_id}"/><creationTime value="{ts}"/>'
               f'<sender><device><id extension="{escape(analyzer_code)}"/></device></sender>'
               f'<controlActProcess><subject><observationReport>{obs}</observationReport></subject></controlActProcess></POLB_IN224100UV01>')
        return xml, message_id
    if fmt == "FHIR":
        import json
        entries = [{"fullUrl": "urn:uuid:spec", "resource": {"resourceType": "Specimen", "id": "spec", "accessionIdentifier": {"value": sample_barcode}}},
                   {"fullUrl": "urn:uuid:dev", "resource": {"resourceType": "Device", "id": "dev", "identifier": [{"value": analyzer_code}]}}]
        for a in analytes:
            entries.append({"resource": {"resourceType": "Observation", "status": "final",
                                         "code": {"coding": [{"system": "http://loinc.org", "code": a["code"], "display": a["name"]}]},
                                         "specimen": {"reference": "Specimen/spec"}, "device": {"reference": "Device/dev"},
                                         "effectiveDateTime": now.isoformat(), "valueQuantity": {"value": a["value"], "unit": a["unit"]},
                                         "referenceRange": [{"text": a["range"]}], "interpretation": [{"coding": [{"code": a["flag"]}]}]}})
        return json.dumps({"resourceType": "Bundle", "id": message_id, "type": "collection", "entry": entries}), message_id
    raise ValueError("format must be HL7V2, HL7V3 or FHIR")

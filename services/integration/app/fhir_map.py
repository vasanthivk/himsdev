"""
Maps HIMS event payloads (camelCase JSON, exactly as the .NET services publish them) to FHIR R4 resources.

Every resource carries an identifier  urn:hims:<schema.table> | <primary key>  so the hub can do a conditional update
(PUT [type]?identifier=...) and a re-delivered event never creates a duplicate.
"""
import re
from typing import Optional

ID_SYSTEM = "urn:hims:"
LOINC = "http://loinc.org"
UCUM = "http://unitsofmeasure.org"
SNOMED = "http://snomed.info/sct"
V2_0203 = "http://terminology.hl7.org/CodeSystem/v2-0203"
V2_0074 = "http://terminology.hl7.org/CodeSystem/v2-0074"
ACT_CODE = "http://terminology.hl7.org/CodeSystem/v3-ActCode"
OBS_CATEGORY = "http://terminology.hl7.org/CodeSystem/observation-category"
OBS_INTERP = "http://terminology.hl7.org/CodeSystem/v3-ObservationInterpretation"

GENDER = {"male": "male", "m": "male", "female": "female", "f": "female", "other": "other", "o": "other"}
ENCOUNTER_CLASS = {"OPD": ("AMB", "ambulatory"), "IPD": ("IMP", "inpatient encounter"), "EMERGENCY": ("EMER", "emergency"),
                   "DAYCARE": ("SS", "short stay"), "TELECONSULT": ("VR", "virtual")}
ENCOUNTER_STATUS = {"PLANNED": "planned", "OPEN": "in-progress", "IN_PROGRESS": "in-progress", "COMPLETED": "finished", "CANCELLED": "cancelled"}
PRIORITY = {"ROUTINE": "routine", "URGENT": "urgent", "STAT": "stat"}
INTERPRETATION = {"N": "Normal", "L": "Low", "H": "High", "LL": "Critical low", "HH": "Critical high", "A": "Abnormal"}


def system_for(entity_type: str) -> str:
    return ID_SYSTEM + entity_type


def identifier(entity_type: str, entity_id) -> dict:
    return {"system": system_for(entity_type), "value": str(entity_id)}


def ref(resource_type: str, fhir_id: Optional[str]) -> Optional[dict]:
    return {"reference": f"{resource_type}/{fhir_id}"} if fhir_id else None


def logical_ref(entity_type: str, entity_id, display: Optional[str] = None) -> Optional[dict]:
    """Reference by identifier only, for things the hub does not mirror (e.g. practitioners)."""
    if entity_id is None:
        return None
    out = {"type": "Practitioner" if entity_type == "hr.practitioner" else None, "identifier": identifier(entity_type, entity_id), "display": display}
    return out


def clean(x):
    """Drops None / empty values recursively so the resources stay valid FHIR (no nulls, no empty arrays)."""
    if isinstance(x, dict):
        out = {k: clean(v) for k, v in x.items()}
        return {k: v for k, v in out.items() if v not in (None, "", [], {})}
    if isinstance(x, list):
        return [v for v in (clean(i) for i in x) if v not in (None, "", [], {})]
    return x


def _code_system(code: str) -> str:
    return LOINC if re.fullmatch(r"\d{1,7}-\d", code or "") else "urn:hims:lab-parameter"


def patient_resource(d: dict) -> dict:
    identifiers = [identifier("pat.patient", d["patientId"])]
    if d.get("uhid"):
        identifiers.append({"use": "usual", "type": {"coding": [{"system": V2_0203, "code": "MR", "display": "Medical record number"}]},
                            "system": "urn:hims:uhid", "value": d["uhid"]})
    if d.get("abhaNumber"):
        identifiers.append({"system": "https://healthid.ndhm.gov.in", "value": d["abhaNumber"]})
    given = [g for g in (d.get("firstName"), d.get("middleName")) if g]
    telecom = []
    if d.get("mobile"):
        telecom.append({"system": "phone", "value": d["mobile"], "use": "mobile"})
    if d.get("email"):
        telecom.append({"system": "email", "value": d["email"]})
    res = {
        "resourceType": "Patient", "identifier": identifiers, "active": not d.get("isDeceased", False),
        "name": [{"use": "official", "prefix": [d["title"]] if d.get("title") else None, "given": given, "family": d.get("lastName")}],
        "telecom": telecom, "gender": GENDER.get((d.get("gender") or "").lower(), "unknown"), "birthDate": d.get("dateOfBirth"),
        "address": [{"line": [d.get("addressLine1"), d.get("addressLine2")], "city": d.get("city"), "district": d.get("district"),
                     "state": d.get("stateCode"), "postalCode": d.get("pincode"), "country": d.get("countryCode")}],
    }
    if d.get("isDeceased"):
        res["deceasedBoolean"] = True
    return clean(res)


def encounter_resource(d: dict, patient_fhir_id: str) -> dict:
    code, display = ENCOUNTER_CLASS.get((d.get("encounterType") or "OPD").upper(), ("AMB", "ambulatory"))
    return clean({
        "resourceType": "Encounter", "identifier": [identifier("pat.encounter", d["encounterId"]), {"system": "urn:hims:encounter-no", "value": d.get("encounterNo")}],
        "status": ENCOUNTER_STATUS.get((d.get("encounterStatus") or "OPEN").upper(), "in-progress"),
        "class": {"system": ACT_CODE, "code": code, "display": display},
        "subject": ref("Patient", patient_fhir_id),
        "participant": [{"individual": logical_ref("hr.practitioner", d.get("attendingPractitionerId"))}] if d.get("attendingPractitionerId") else None,
        "period": {"start": d.get("startAt"), "end": d.get("endAt")},
    })


def service_request_resource(order: dict, item: dict, patient_fhir_id: str, encounter_fhir_id: Optional[str]) -> dict:
    category = {"LAB": ("108252007", "Laboratory procedure"), "RADIOLOGY": ("363679005", "Imaging")}.get((order.get("orderCategory") or "").upper())
    cancelled = (item.get("itemStatus") or "").upper() == "CANCELLED"
    return clean({
        "resourceType": "ServiceRequest",
        "identifier": [identifier("ord.order_item", item["orderItemId"]), {"system": "urn:hims:order-no", "value": order.get("orderNo")}],
        "status": "revoked" if cancelled else "active", "intent": "order",
        "category": [{"coding": [{"system": SNOMED, "code": category[0], "display": category[1]}]}] if category else None,
        "priority": PRIORITY.get((order.get("priority") or "ROUTINE").upper(), "routine"),
        "code": {"coding": [{"system": "urn:hims:service", "code": item.get("serviceCode"), "display": item.get("serviceName")}], "text": item.get("serviceName")},
        "subject": ref("Patient", patient_fhir_id), "encounter": ref("Encounter", encounter_fhir_id), "authoredOn": order.get("orderedAt"),
        "requester": logical_ref("hr.practitioner", order.get("orderingPractitionerId")),
        "note": [{"text": item["instructions"]}] if item.get("instructions") else None,
    })


def medication_request_resource(rx: dict, item: dict, patient_fhir_id: str, encounter_fhir_id: Optional[str]) -> dict:
    dose = None
    if item.get("dose") is not None:
        dose = [{"doseQuantity": {"value": item["dose"], "unit": item.get("doseUnit")}}]
    text_parts = [str(item[k]) for k in ("dose", "doseUnit", "frequency", "timing") if item.get(k) is not None]
    if item.get("durationValue"):
        text_parts.append(f"for {item['durationValue']} {item.get('durationUnit') or 'days'}")
    dosage = {
        "text": " ".join(text_parts) or None, "patientInstruction": item.get("instructions"),
        "timing": {"code": {"text": item.get("frequency")}} if item.get("frequency") else None,
        "route": {"text": item["route"]} if item.get("route") else None, "doseAndRate": dose,
    }
    return clean({
        "resourceType": "MedicationRequest",
        "identifier": [identifier("ord.prescription_item", item["prescriptionItemId"]), {"system": "urn:hims:prescription-no", "value": rx.get("prescriptionNo")}],
        "status": "active", "intent": "order",
        "medicationCodeableConcept": {"text": item.get("drugText")},
        "subject": ref("Patient", patient_fhir_id), "encounter": ref("Encounter", encounter_fhir_id), "authoredOn": rx.get("prescribedAt"),
        "requester": logical_ref("hr.practitioner", rx.get("practitionerId")),
        "dosageInstruction": [dosage],
        "dispenseRequest": {"quantity": {"value": item["quantity"]}} if item.get("quantity") is not None else None,
        "note": [{"text": rx["advice"]}] if rx.get("advice") else None,
    })


def observation_resource(report: dict, r: dict, patient_fhir_id: str, encounter_fhir_id: Optional[str], service_request_fhir_id: Optional[str]) -> dict:
    code = r.get("parameterCode") or ""
    value = {}
    if r.get("valueNumeric") is not None:
        unit = r.get("unit")
        value["valueQuantity"] = {"value": r["valueNumeric"], "unit": unit, "system": UCUM if unit else None, "code": unit}
    elif r.get("valueText"):
        value["valueString"] = r["valueText"]
    flag = (r.get("abnormalFlag") or "").upper()
    interp = [{"coding": [{"system": OBS_INTERP, "code": flag, "display": INTERPRETATION.get(flag)}]}] if flag in INTERPRETATION else None
    return clean({
        "resourceType": "Observation", "identifier": [identifier("lab.result", r["resultId"])], "status": "final",
        "basedOn": [ref("ServiceRequest", service_request_fhir_id)] if service_request_fhir_id else None,
        "category": [{"coding": [{"system": OBS_CATEGORY, "code": "laboratory", "display": "Laboratory"}]}],
        "code": {"coding": [{"system": _code_system(code), "code": code, "display": r.get("parameterName")}], "text": r.get("parameterName")},
        "subject": ref("Patient", patient_fhir_id), "encounter": ref("Encounter", encounter_fhir_id),
        "effectiveDateTime": r.get("resultedAt") or report.get("releasedAt"), "issued": report.get("releasedAt"),
        **value, "interpretation": interp,
        "referenceRange": [{"text": r["referenceRangeText"]}] if r.get("referenceRangeText") else None,
        "device": {"display": r["analyzerCode"]} if r.get("analyzerCode") else None,
        "note": [{"text": "Critical value"}] if r.get("isCritical") else None,
    })


def diagnostic_report_resource(report: dict, observation_fhir_ids: list, patient_fhir_id: str, encounter_fhir_id: Optional[str]) -> dict:
    return clean({
        "resourceType": "DiagnosticReport",
        "identifier": [identifier("lab.report", report["labReportId"]), {"system": "urn:hims:sample-barcode", "value": report.get("sampleBarcode")}],
        "status": "final",
        "category": [{"coding": [{"system": V2_0074, "code": "LAB", "display": "Laboratory"}]}],
        "code": {"coding": [{"system": LOINC, "code": "11502-2", "display": "Laboratory report"}]},
        "subject": ref("Patient", patient_fhir_id), "encounter": ref("Encounter", encounter_fhir_id),
        "effectiveDateTime": report.get("releasedAt"), "issued": report.get("releasedAt"),
        "result": [ref("Observation", i) for i in observation_fhir_ids],
    })

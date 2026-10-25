"""Realistic device messages used by the tests and by the simulator."""

HL7V2_CBC = "\r".join([
    "MSH|^~\\&|SYSMEX-XN|LAB|HIMS|DRR|20260928103015+0530||ORU^R01|MSG0001|P|2.5.1",
    "PID|1||DR26000001||REDDY^ANIL",
    "OBR|1|ORD26000001|SMP26000001|58410-2^CBC panel^LN|||20260928101500+0530|||||||||||||||20260928103000+0530|||F",
    "OBX|1|NM|6690-2^WBC^LN||7.2|10*3/uL|4.0-11.0|N|||F|||20260928103010+0530",
    "OBX|2|NM|718-7^Haemoglobin^LN||6.1|g/dL|13.0-17.0|LL|||F|||20260928103010+0530",
    "OBX|3|NM|777-3^Platelets^LN||245|10*3/uL|150-410|N|||F",
    "OBX|4|ST|X-COMMENT^Comment^L||Sample slightly haemolysed||||||F",
    "",
])

HL7V3_GLUCOSE = """<?xml version="1.0" encoding="UTF-8"?>
<POLB_IN224100UV01 xmlns="urn:hl7-org:v3" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <id root="2.16.840.1.113883.19.1122.7" extension="V3-MSG-77"/>
  <creationTime value="20260928104500"/>
  <sender><device><id extension="ROCHE-COBAS"/></device></sender>
  <controlActProcess>
    <subject><observationReport>
      <component><observationEvent>
        <code code="1558-6" displayName="Fasting Glucose" codeSystem="2.16.840.1.113883.6.1"/>
        <effectiveTime value="20260928104400"/>
        <value xsi:type="PQ" value="132" unit="mg/dL"/>
        <interpretationCode code="H"/>
        <specimen><specimenRole><id extension="SMP26000002"/></specimenRole></specimen>
        <referenceRange><observationRange><value><low value="70"/><high value="100"/></value></observationRange></referenceRange>
      </observationEvent></component>
    </observationReport></subject>
  </controlActProcess>
</POLB_IN224100UV01>"""

FHIR_BUNDLE = """{
 "resourceType": "Bundle", "id": "fhir-msg-9", "type": "collection",
 "entry": [
  {"fullUrl": "urn:uuid:spec1", "resource": {"resourceType": "Specimen", "id": "spec1", "accessionIdentifier": {"value": "SMP26000003"}}},
  {"fullUrl": "urn:uuid:dev1", "resource": {"resourceType": "Device", "id": "dev1", "identifier": [{"value": "MINDRAY-BS"}]}},
  {"resource": {"resourceType": "Observation", "status": "final", "code": {"coding": [{"system": "http://loinc.org", "code": "2093-3", "display": "Total Cholesterol"}]},
    "specimen": {"reference": "Specimen/spec1"}, "device": {"reference": "Device/dev1"}, "effectiveDateTime": "2026-09-28T11:00:00+05:30",
    "valueQuantity": {"value": 238, "unit": "mg/dL"}, "referenceRange": [{"text": "<200"}], "interpretation": [{"coding": [{"code": "H"}]}]}},
  {"resource": {"resourceType": "Observation", "status": "final", "code": {"coding": [{"system": "http://loinc.org", "code": "2571-8", "display": "Triglycerides"}]},
    "specimen": {"reference": "Specimen/spec1"}, "valueQuantity": {"value": 150, "unit": "mg/dL"}}}
 ]}"""

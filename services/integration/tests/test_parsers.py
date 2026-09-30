from datetime import timezone
from decimal import Decimal

import pytest

from app.parsers import ParseError, build_hl7v2_ack, detect_format, parse_message, parse_hl7_timestamp
from tests import samples


def test_detect_format():
    assert detect_format(samples.HL7V2_CBC) == "HL7V2"
    assert detect_format("\x0b" + samples.HL7V2_CBC) == "HL7V2"          # MLLP start byte tolerated
    assert detect_format(samples.HL7V3_GLUCOSE) == "HL7V3"
    assert detect_format(samples.FHIR_BUNDLE) == "FHIR"
    with pytest.raises(ParseError):
        detect_format("hello")


def test_hl7v2_oru_cbc():
    m = parse_message(samples.HL7V2_CBC)
    assert (m.format, m.message_id, m.message_type) == ("HL7V2", "MSG0001", "ORU^R01")
    assert m.sample_barcode == "SMP26000001"           # from OBR-3, first component
    assert m.analyzer_code == "SYSMEX-XN"              # MSH-3
    assert [a.parameter_code for a in m.analytes] == ["6690-2", "718-7", "777-3", "X-COMMENT"]
    wbc, hgb, plt, note = m.analytes
    assert wbc.value_numeric == Decimal("7.2") and wbc.unit == "10*3/uL" and wbc.reference_range_text == "4.0-11.0" and not wbc.is_critical
    assert hgb.abnormal_flag == "LL" and hgb.is_critical                  # LL = critical low
    assert plt.value_numeric == Decimal("245")
    assert note.value_numeric is None and note.value_text == "Sample slightly haemolysed"
    # OBR-22 is 10:30:00 +05:30, which is 05:00 UTC
    assert m.resulted_at.astimezone(timezone.utc).strftime("%H:%M") == "05:00"
    assert m.resulted_at.utcoffset().total_seconds() == 5.5 * 3600


def test_hl7v2_rejects_bad_messages():
    with pytest.raises(ParseError, match="MSH"):
        parse_message("PID|1||X")
    no_obx = "MSH|^~\\&|A|B|C|D|20260101||ORU^R01|1|P|2.5\rOBR|1||SMP1"
    with pytest.raises(ParseError, match="OBX"):
        parse_message(no_obx)
    no_barcode = "MSH|^~\\&|A|B|C|D|20260101||ORU^R01|1|P|2.5\rOBR|1\rOBX|1|NM|X^Y||1|u"
    with pytest.raises(ParseError, match="barcode"):
        parse_message(no_barcode)
    adt = "MSH|^~\\&|A|B|C|D|20260101||ADT^A01|1|P|2.5\rPID|1"
    with pytest.raises(ParseError, match="Unsupported"):
        parse_message(adt)


def test_hl7v2_uses_spm_for_barcode_and_structured_numeric():
    raw = "\r".join(["MSH|^~\\&|X|B|C|D|20260101120000||ORU^R01|C1|P|2.5.1", "SPM|1|BAR777&LIS||BLD", "OBR|1|||T^Test",
                     "OBX|1|SN|1558-6^Glucose||<^20|mg/dL||N|||F"])
    m = parse_message(raw)
    assert m.sample_barcode == "BAR777"
    assert m.analytes[0].value_numeric == Decimal("20") and m.analytes[0].value_text == "<20"


def test_hl7v2_ack():
    ack = build_hl7v2_ack(samples.HL7V2_CBC, True)
    assert "MSA|AA|MSG0001" in ack and ack.startswith("MSH|^~\\&|HIMS-HUB")
    assert "MSA|AE|MSG0001|bad" in build_hl7v2_ack(samples.HL7V2_CBC, False, "bad")


def test_hl7v3_observation():
    m = parse_message(samples.HL7V3_GLUCOSE)
    assert m.format == "HL7V3" and m.message_id == "V3-MSG-77" and m.message_type == "POLB_IN224100UV01"
    assert m.sample_barcode == "SMP26000002" and m.analyzer_code == "ROCHE-COBAS"
    a = m.analytes[0]
    assert (a.parameter_code, a.parameter_name, a.value_numeric, a.unit, a.abnormal_flag) == ("1558-6", "Fasting Glucose", Decimal("132"), "mg/dL", "H")
    assert a.reference_range_text == "70 - 100"


def test_hl7v3_errors():
    with pytest.raises(ParseError, match="Invalid HL7 v3"):
        parse_message("<a><b></a>")
    with pytest.raises(ParseError, match="barcode"):
        parse_message('<X xmlns="urn:hl7-org:v3"><id root="1"/></X>')


def test_fhir_bundle():
    m = parse_message(samples.FHIR_BUNDLE)
    assert m.format == "FHIR" and m.message_id == "fhir-msg-9" and m.sample_barcode == "SMP26000003" and m.analyzer_code == "MINDRAY-BS"
    chol, tg = m.analytes
    assert chol.parameter_code == "2093-3" and chol.value_numeric == Decimal("238") and chol.unit == "mg/dL"
    assert chol.abnormal_flag == "H" and chol.reference_range_text == "<200"
    assert tg.value_numeric == Decimal("150")
    assert m.resulted_at.utcoffset().total_seconds() == 5.5 * 3600


def test_fhir_errors():
    with pytest.raises(ParseError, match="Observation"):
        parse_message('{"resourceType":"Bundle","entry":[]}')
    with pytest.raises(ParseError, match="barcode"):
        parse_message('{"resourceType":"Observation","code":{"coding":[{"code":"x"}]},"valueString":"1"}')


def test_event_payload_shape_matches_dotnet_contract():
    m = parse_message(samples.HL7V2_CBC)
    p = m.to_event_payload(42, analyzer_override="SYSMEX-1")
    assert set(p) == {"sampleBarcode", "analyzerCode", "sourceMessageId", "messageType", "resultedAt", "messageLogId", "analytes"}
    assert p["analyzerCode"] == "SYSMEX-1" and p["messageLogId"] == 42 and p["resultedAt"].endswith("Z")
    assert set(p["analytes"][0]) == {"parameterCode", "machineTestCode", "parameterName", "valueNumeric", "valueText", "unit", "referenceRangeText", "abnormalFlag", "isCritical"}


def test_timestamp_parsing():
    assert parse_hl7_timestamp("20260928").day == 28
    assert parse_hl7_timestamp("garbage") is None
    assert parse_hl7_timestamp("20260928101500-0400").utcoffset().total_seconds() == -4 * 3600

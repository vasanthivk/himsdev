"""Parses the per-service data-model scripts (database/NN_*.sql) into statements and compares them per consolidated
service, to plan database_v2. Usage: python tools/v2_analyze.py"""
import re
from pathlib import Path

DB = Path(__file__).resolve().parent.parent / "database"

GROUPS = {
    "identity_org": ["10_identity_org"],
    "patient_engagement": ["01_patient_access", "07_digital_engagement"],
    "clinical_care": ["02_clinical_care"],
    "diagnostics": ["03_laboratory", "04_imaging"],
    "revenue_finance": ["06_revenue_cycle", "13_back_office"],
    "operations_supply": ["05_pharmacy_supply", "09_hospital_ops", "08_field_ops"],
    "integration_comms": ["11_integration", "12_comms_docs"],
}


def statements(text):
    """Splits a script into top-level statements (keeps $$-quoted bodies intact). Returns (leading_comment, sql) pairs."""
    out, buf, in_dollar = [], [], False
    for line in text.splitlines(keepends=True):
        buf.append(line)
        if line.count("$$") % 2 == 1:
            in_dollar = not in_dollar
        if not in_dollar and not line.lstrip().startswith("--") and re.search(r";\s*(--.*)?$", line.rstrip("\n")):
            out.append("".join(buf)); buf = []
    if "".join(buf).strip():
        out.append("".join(buf))
    return out


def split_comment(stmt):
    """Leading comment lines/blocks of a statement vs the SQL itself."""
    m = re.match(r"((?:\s*--[^\n]*\n|\s*/\*.*?\*/)*\s*)(.*)", stmt, re.S)
    return m.group(1), m.group(2)


def parse(name):
    text = (DB / f"{name}.sql").read_text(encoding="utf-8")
    items = []
    for st in statements(text):
        comment, sql = split_comment(st)
        head = sql.strip().split("\n")[0]
        if m := re.match(r"CREATE SCHEMA (\w+)", sql.strip(), re.I):
            items.append(("schema", m.group(1), comment, sql))
        elif m := re.match(r"CREATE TABLE (\w+\.\w+)", sql.strip(), re.I):
            items.append(("table", m.group(1), comment, sql))
        elif m := re.match(r"CREATE (?:UNIQUE )?INDEX (\w+)\s+ON\s+(\w+\.\w+)", sql.strip(), re.I):
            items.append(("index", m.group(2) + "|" + m.group(1), comment, sql))
        elif m := re.match(r"CREATE (?:OR REPLACE )?FUNCTION (\w+\.\w+)", sql.strip(), re.I):
            items.append(("function", m.group(1), comment, sql))
        elif sql.strip().upper().startswith("DO"):
            items.append(("do", "row_ver_triggers", comment, sql))
        elif sql.strip():
            items.append(("other", head[:60], comment, sql))
    return items


def columns(table_sql):
    body = table_sql[table_sql.index("(") + 1: table_sql.rindex(")")]
    cols = []
    for line in body.split("\n"):
        line = re.sub(r"--.*", "", line).strip().rstrip(",")
        if not line or re.match(r"(CONSTRAINT|PRIMARY KEY|UNIQUE|FOREIGN KEY|CHECK)\b", line, re.I):
            continue
        parts = line.split(None, 1)
        cols.append((parts[0], parts[1] if len(parts) > 1 else ""))
    return cols


if __name__ == "__main__":
    for group, names in GROUPS.items():
        print(f"\n===== {group}: {', '.join(names)}")
        seen = {}
        for n in names:
            for kind, key, comment, sql in parse(n):
                if kind in ("table", "function", "do", "other"):
                    seen.setdefault((kind, key), []).append((n, sql))
        owned = {k[1]: v[0][0] for k, v in seen.items() if k[0] == "table" and not k[1].startswith(("ref.", "evt."))}
        for (kind, key), defs in sorted(seen.items()):
            if kind == "other":
                print("  OTHER", key, [d[0] for d in defs])
            if len(defs) > 1 or (kind == "table" and key.startswith("ref.")):
                if kind == "table":
                    cols = [columns(d[1]) for d in defs]
                    same = all(c == cols[0] for c in cols)
                    src = key.replace("ref.", "", 1)
                    note = f"  OWNED HERE by {owned[src]}" if key.startswith("ref.") and src in owned else ""
                    # ref tables are named after the source table without schema sometimes; try any owned table with same base name
                    if key.startswith("ref.") and not note:
                        hits = [t for t in owned if t.split(".")[1] == src]
                        note = f"  OWNED HERE as {hits} by {[owned[h] for h in hits]}" if hits else ""
                    if len(defs) > 1 or note:
                        print(f"  {key:40} in {[d[0][:2] for d in defs]} {'same' if same else 'DIFFERENT'}{note}")
                elif len(defs) > 1:
                    same = all(d[1] == defs[0][1] for d in defs)
                    print(f"  {kind} {key:34} in {[d[0][:2] for d in defs]} {'same' if same else 'DIFFERENT'}")

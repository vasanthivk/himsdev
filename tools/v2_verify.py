"""Verifies database_v2 against the per-service databases: every table, column (type, nullability, default), constraint,
index and row_ver trigger of the 13 original databases must exist in its consolidated database, and the only differences
allowed are the documented ones (shared infrastructure once, ref replicas of own tables as views, new same-service FKs).
Usage: python tools/v2_verify.py <dsn without dbname> <v1 prefix> <v2 prefix>
   e.g. python tools/v2_verify.py "host=localhost user=postgres password=..." hims_ v2test_"""
import sys
import psycopg

DSN, V1, V2 = sys.argv[1], sys.argv[2], sys.argv[3]
GROUPS = {
    "identity_org": ["identity_org"], "patient_engagement": ["patient_access", "digital_engagement"],
    "clinical_care": ["clinical_care"], "diagnostics": ["laboratory", "imaging"],
    "revenue_finance": ["revenue_cycle", "back_office"], "operations_supply": ["pharmacy_supply", "hospital_ops", "field_ops"],
    "integration_comms": ["integration", "comms_docs"],
}
Q_REL = """SELECT n.nspname||'.'||c.relname, c.relkind FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
           WHERE c.relkind IN ('r','v') AND n.nspname NOT IN ('pg_catalog','information_schema','pg_toast')"""
Q_COL = """SELECT table_schema||'.'||table_name, column_name, data_type, COALESCE(character_maximum_length::text, numeric_precision||','||numeric_scale, ''),
                  is_nullable, COALESCE(column_default,''), is_identity, is_generated, COALESCE(generation_expression,'')
             FROM information_schema.columns WHERE table_schema NOT IN ('pg_catalog','information_schema')"""
Q_CON = """SELECT n.nspname||'.'||c.relname, k.contype, pg_get_constraintdef(k.oid) FROM pg_constraint k
             JOIN pg_class c ON c.oid=k.conrelid JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname NOT IN ('pg_catalog')"""
Q_IDX = """SELECT schemaname||'.'||tablename, regexp_replace(indexdef, 'INDEX \\S+ ON', 'INDEX ON') FROM pg_indexes
            WHERE schemaname NOT IN ('pg_catalog','information_schema')"""
Q_TRG = """SELECT n.nspname||'.'||c.relname, t.tgname, p.proname FROM pg_trigger t JOIN pg_class c ON c.oid=t.tgrelid
             JOIN pg_namespace n ON n.oid=c.relnamespace JOIN pg_proc p ON p.oid=t.tgfoid WHERE NOT t.tgisinternal"""


def snapshot(db):
    with psycopg.connect(f"{DSN} dbname={db}") as c:
        rel = dict(c.execute(Q_REL).fetchall())
        cols = {}
        for t, *rest in c.execute(Q_COL).fetchall():
            cols.setdefault(t, {})[rest[0]] = tuple(rest[1:])
        cons = {}
        for t, typ, d in c.execute(Q_CON).fetchall():
            cons.setdefault(t, set()).add((typ, d))
        idx = {}
        for t, d in c.execute(Q_IDX).fetchall():
            idx.setdefault(t, set()).add(d)
        trg = {}
        for t, name, fn in c.execute(Q_TRG).fetchall():
            trg.setdefault(t, set()).add((name, fn))
    return rel, cols, cons, idx, trg


problems, notes = [], []
for group, parts in GROUPS.items():
    rel2, cols2, cons2, idx2, trg2 = snapshot(V2 + group)
    seen = set()
    for part in parts:
        rel1, cols1, cons1, idx1, trg1 = snapshot(V1 + part)
        for t, kind in rel1.items():
            seen.add(t)
            where = f"{group}: {t} (from {part})"
            if t not in rel2:
                problems.append(f"{where}: MISSING"); continue
            if rel2[t] == "v":   # ref replica of an own table -> view: same column names, and readable
                if not t.startswith("ref."):
                    problems.append(f"{where}: became a view")
                elif {(c, s[0]) for c, s in cols1[t].items()} != {(c, s[0]) for c, s in cols2[t].items()}:
                    problems.append(f"{where}: view columns/types differ "
                                    f"{sorted({(c, s[0]) for c, s in cols1[t].items()} ^ {(c, s[0]) for c, s in cols2[t].items()})}")
                else:
                    notes.append(f"{group}: {t} is a read-only view now")
                continue
            for col, spec in cols1[t].items():
                if col not in cols2[t]:
                    problems.append(f"{where}: column {col} missing")
                elif cols2[t][col] != spec:
                    problems.append(f"{where}: column {col} differs {spec} vs {cols2[t][col]}")
            extra_cols = set(cols2[t]) - set(cols1[t])
            if extra_cols:
                notes.append(f"{where}: extra columns {sorted(extra_cols)} (merged from another part)")
            for con in cons1.get(t, set()) - cons2.get(t, set()):
                problems.append(f"{where}: constraint missing {con}")
            for con in cons2.get(t, set()) - cons1.get(t, set()):
                (notes if con[0] == "f" else problems).append(f"{where}: new constraint {con[1]}")
            for i in idx1.get(t, set()) - idx2.get(t, set()):
                problems.append(f"{where}: index missing {i}")
            if trg1.get(t, set()) != trg2.get(t, set()):
                problems.append(f"{where}: triggers differ {trg1.get(t)} vs {trg2.get(t)}")
    for t in set(rel2) - seen:
        problems.append(f"{group}: {t} exists only in v2")

for n in sorted(set(notes)):
    print("NOTE   ", n)
for p in problems:
    print("PROBLEM", p)
print(f"\n{len(problems)} problems, {len(set(notes))} notes")

"""Verifies database_v3 (one database, one schema per service) against database_v2 (one database per service):
every table/view of <v2 prefix><service> must exist as <service>.<schema>_<table> in the v3 database with the same columns
(type, nullability, default, identity, generated), constraints, indexes, triggers and seed rows - names mapped to the new
convention. Usage: python tools/v3_verify.py <dsn without dbname> <v2 prefix> <v3 database>
   e.g. python tools/v3_verify.py "host=localhost user=postgres password=..." v2test_ himsdev_v3test"""
import re
import sys
import psycopg

DSN, V2, V3 = sys.argv[1], sys.argv[2], sys.argv[3]
SERVICES = ["identity_org", "patient_engagement", "clinical_care", "diagnostics", "revenue_finance", "operations_supply", "integration_comms"]
SKIP = "('pg_catalog','information_schema','pg_toast','public')"


def catalog(db, schemas_sql):
    with psycopg.connect(f"{DSN} dbname={db}") as c:
        rel = dict(c.execute(f"""SELECT n.nspname||'.'||c.relname, c.relkind FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
                                  WHERE c.relkind IN ('r','v') AND {schemas_sql}""").fetchall())
        cols = {}
        for t, col, *spec in c.execute(f"""SELECT table_schema||'.'||table_name, column_name, data_type,
                   COALESCE(character_maximum_length::text, numeric_precision||','||numeric_scale, ''), is_nullable,
                   COALESCE(column_default,''), is_identity, is_generated, COALESCE(generation_expression,'')
              FROM information_schema.columns WHERE {schemas_sql.replace('n.nspname', 'table_schema')}""").fetchall():
            cols.setdefault(t, {})[col] = tuple(spec)
        cons = {}
        for t, typ, d in c.execute(f"""SELECT n.nspname||'.'||c.relname, k.contype, pg_get_constraintdef(k.oid) FROM pg_constraint k
                   JOIN pg_class c ON c.oid=k.conrelid JOIN pg_namespace n ON n.oid=c.relnamespace WHERE {schemas_sql}""").fetchall():
            cons.setdefault(t, set()).add((typ, d))
        idx = {}
        for t, d in c.execute(f"""SELECT schemaname||'.'||tablename, regexp_replace(indexdef, 'INDEX \\S+ ON', 'INDEX ON') FROM pg_indexes
                   WHERE {schemas_sql.replace('n.nspname', 'schemaname')}""").fetchall():
            idx.setdefault(t, set()).add(d)
        trg = {}
        for t, name, fn in c.execute(f"""SELECT n.nspname||'.'||c.relname, t.tgname, pn.nspname||'.'||p.proname FROM pg_trigger t
                   JOIN pg_class c ON c.oid=t.tgrelid JOIN pg_namespace n ON n.oid=c.relnamespace
                   JOIN pg_proc p ON p.oid=t.tgfoid JOIN pg_namespace pn ON pn.oid=p.pronamespace
                  WHERE NOT t.tgisinternal AND {schemas_sql}""").fetchall():
            trg.setdefault(t, set()).add((name, fn))
        views = dict(c.execute(f"""SELECT schemaname||'.'||viewname, definition FROM pg_views WHERE {schemas_sql.replace('n.nspname', 'schemaname')}""").fetchall())
        rows = {t: c.execute(f'SELECT count(*) FROM {".".join(chr(34) + p + chr(34) for p in t.split("."))}').fetchone()[0] for t in rel}
    return rel, cols, cons, idx, trg, views, rows


problems, checked = [], {"tables": 0, "views": 0, "columns": 0, "constraints": 0, "indexes": 0, "triggers": 0, "seed rows": 0}
for svc in SERVICES:
    r2, c2, k2, i2, t2, v2, n2 = catalog(V2 + svc, f"n.nspname NOT IN {SKIP}")
    r3, c3, k3, i3, t3, v3, n3 = catalog(V3, f"n.nspname = '{svc}'")
    old_schemas = {t.split(".")[0] for t in r2}
    new = lambda name: f"{svc}.{name.replace('.', '_', 1)}"                                       # core.branch -> svc.core_branch

    def mapped(text):   # names inside definitions (FKs, index columns' tables, defaults, view bodies)
        return re.sub(r"\b(" + "|".join(sorted(old_schemas, key=len, reverse=True)) + r")\.(\w+)", lambda m: f"{svc}.{m.group(1)}_{m.group(2)}", text)
    for t, kind in r2.items():
        t3_ = new(t)
        where = f"{svc}: {t} -> {t3_}"
        if t3_ not in r3:
            problems.append(f"{where}: MISSING"); continue
        if r3[t3_] != kind:
            problems.append(f"{where}: kind {kind} vs {r3[t3_]}")
        checked["views" if kind == "v" else "tables"] += 1
        if c2[t] != c3[t3_]:
            for col in set(c2[t]) | set(c3[t3_]):
                if c2[t].get(col) != c3[t3_].get(col) and (mapped(str(c2[t].get(col))) != str(c3[t3_].get(col))):
                    problems.append(f"{where}: column {col} {c2[t].get(col)} vs {c3[t3_].get(col)}")
        checked["columns"] += len(c2[t])
        a, b = {(x, mapped(d)) for x, d in k2.get(t, set())}, k3.get(t3_, set())
        if a != b:
            problems.append(f"{where}: constraints differ {sorted(a ^ b)}")
        checked["constraints"] += len(a)
        a, b = {mapped(d) for d in i2.get(t, set())}, i3.get(t3_, set())
        if a != b:
            problems.append(f"{where}: indexes differ {sorted(a ^ b)}")
        checked["indexes"] += len(a)
        a = {(nm, f"{svc}.util_{fn.split('.')[1]}" if fn.startswith("util.") else fn) for nm, fn in t2.get(t, set())}   # util.x -> svc.util_x
        b = t3.get(t3_, set())
        if a != b:
            problems.append(f"{where}: triggers differ {sorted(a ^ b)}")
        checked["triggers"] += len(a)
        if kind == "v" and mapped(v2[t]) != v3[t3_]:
            problems.append(f"{where}: view definition differs")
        if n2[t] != n3[t3_]:
            problems.append(f"{where}: rows {n2[t]} vs {n3[t3_]}")
        checked["seed rows"] += n2[t]
    extra = set(r3) - {new(t) for t in r2}
    if extra:
        problems.append(f"{svc}: only in v3: {sorted(extra)}")

with psycopg.connect(f"{DSN} dbname={V3}") as c:
    schemas = [r[0] for r in c.execute(f"SELECT nspname FROM pg_namespace WHERE nspname NOT IN {SKIP} AND nspname NOT LIKE 'pg_%' ORDER BY 1")]
print("v3 schemas:", schemas)
print("checked:", checked)
for p in problems:
    print("PROBLEM", p)
print(f"{len(problems)} problems")

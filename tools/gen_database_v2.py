"""Generates database_v2/: one database script per consolidated microservice (7 instead of 13), built from the per-service
scripts in database/ (see config/microservices_consolidation.xlsx). Usage: python tools/gen_database_v2.py

What the merge does, per consolidated service:
  * owned tables, indexes and comments are copied unchanged, part by part, in the original order;
  * infrastructure every source script repeats (core.number_sequence, evt.outbox/inbox/saga_instance, util functions,
    the row_ver trigger block) is created once;
  * a ref.* replica that two parts both had is created once (columns merged when the parts differ);
  * a ref.* replica of a table that another part of the SAME service owns is no longer needed: it becomes a read-only
    view of the same name over the owner table (source_version = row_ver, replicated_at = updated_at/created_at), so code
    that reads the replica still works while the data is stored once;
  * a 'logical FK' to a table now owned by the same service becomes a real FOREIGN KEY (the data model's rule: foreign
    keys between tables inside one service are kept).
"""
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from v2_analyze import columns, statements, split_comment  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
SRC, OUT = ROOT / "database", ROOT / "database_v2"

# (file, database, title, parts) - parts in an order where an owner part comes before the parts that reference it.
SERVICES = [
    ("01_identity_org", "new_hims_identity_org", "Identity & Organization", ["10_identity_org"]),
    ("02_patient_engagement", "new_hims_patient_engagement", "Patient Access & Engagement", ["01_patient_access", "07_digital_engagement"]),
    ("03_clinical_care", "new_hims_clinical_care", "Clinical Care", ["02_clinical_care"]),
    ("04_diagnostics", "new_hims_diagnostics", "Diagnostics (Lab + Imaging)", ["03_laboratory", "04_imaging"]),
    ("05_revenue_finance", "new_hims_revenue_finance", "Revenue & Finance", ["06_revenue_cycle", "13_back_office"]),
    ("06_operations_supply", "new_hims_operations_supply", "Operations & Supply Chain", ["05_pharmacy_supply", "09_hospital_ops", "08_field_ops"]),
    ("07_integration_comms", "new_hims_integration_comms", "Integration & Communications", ["11_integration", "12_comms_docs"]),
]
EXTENSIONS = {"03_laboratory": "03_laboratory.ext.sql"}
SEEDS = {"10_identity_org": "01_identity_org", "06_revenue_cycle": "05_revenue_finance", "03_laboratory": "04_diagnostics"}
SHARED_INFRA = ("core.number_sequence", "evt.outbox", "evt.inbox", "evt.saga_instance")

RULE = "=" * 85


def load(part):
    """The part's statements as dicts: kind, key, comment (leading), sql; plus its header comment block."""
    text = (SRC / f"{part}.sql").read_text(encoding="utf-8")
    items, header = [], ""
    for i, st in enumerate(statements(text)):
        comment, sql = split_comment(st)
        s = sql.strip()
        if i == 0:   # "-- Run once ..." + the /* ==== */ header + the SCHEMAS banner precede the first statement
            m = re.search(r"/\*\s*=+.*?=+\s*\*/", comment, re.S)
            header = m.group(0) if m else ""
            comment = ""
        if m := re.match(r"CREATE SCHEMA (?:IF NOT EXISTS )?(\w+)", s, re.I):
            kind, key = "schema", m.group(1)
        elif m := re.match(r"CREATE TABLE (\w+\.\w+)", s, re.I):
            kind, key = "table", m.group(1)
        elif m := re.match(r"CREATE (?:UNIQUE )?INDEX (\w+)\s+ON\s+(\w+\.\w+)", s, re.I):
            kind, key = "index", m.group(2)
        elif re.match(r"CREATE (?:OR REPLACE )?FUNCTION", s, re.I) or s.upper().startswith("DO"):
            kind, key = "housekeeping", ""
        else:
            kind, key = "comment", ""
        items.append({"kind": kind, "key": key, "comment": comment, "sql": sql})
    return items, header


def pk_column(table_sql):
    for name, rest in columns(table_sql):
        if "PRIMARY KEY" in rest.upper():
            return name
    raise ValueError("no single-column primary key in " + table_sql[:80])


def view_for(ref_sql, ref_name, owner_name, owner_sql, owner_part):
    owner_cols = {c for c, _ in columns(owner_sql)}
    select = []
    for col, _ in columns(ref_sql):
        if col in owner_cols:
            select.append(col)
        elif col == "source_version":
            select.append("row_ver::BIGINT AS source_version")
        elif col == "replicated_at":
            ts = "COALESCE(updated_at, created_at)" if {"updated_at", "created_at"} <= owner_cols else "CURRENT_TIMESTAMP"
            select.append(f"{ts} AS replicated_at")
        else:
            raise ValueError(f"{ref_name}.{col} has no source column in {owner_name}")
    cols = ",\n       ".join(select)
    return (f"-- {ref_name} was an event-filled replica of {owner_name} [{owner_part}]. Both are in this database now, so it is a\n"
            f"-- read-only view of the owner table (same name and columns): the data is stored once and is always current.\n"
            f"CREATE VIEW {ref_name} AS\nSELECT {cols}\n  FROM {owner_name};\n\n"
            f"CREATE TRIGGER trg_read_only INSTEAD OF INSERT OR UPDATE OR DELETE ON {ref_name}\n"
            f"    FOR EACH ROW EXECUTE FUNCTION util.reject_write();\n")


def merge_columns(base_sql, extra_sql):
    """base_sql plus the columns only extra_sql has (inserted before source_version)."""
    have = {c for c, _ in columns(base_sql)}
    missing = [line for line in extra_sql.splitlines()
               if (m := re.match(r"\s+(\w+)\s", line)) and m.group(1) not in have and not re.match(r"\s+(CONSTRAINT|PRIMARY|UNIQUE)\b", line)]
    if not missing:
        return base_sql
    lines = base_sql.splitlines()
    at = next(i for i, l in enumerate(lines) if re.match(r"\s+source_version\s", l))
    return "\n".join(lines[:at] + [l if l.rstrip().endswith(",") else l + "," for l in missing] + lines[at:]) + "\n"


def generate(file, database, title, parts):
    loaded = {p: load(p) for p in parts}
    # tables each part owns (not replicas / infrastructure), with their SQL
    owned = {}
    for p in parts:
        for it in loaded[p][0]:
            if it["kind"] == "table" and not it["key"].startswith(("ref.", "evt.")) and it["key"] != "core.number_sequence":
                owned[it["key"]] = (p, it["sql"])
    # the widest definition of every replica that more than one part has
    ref_defs = {}
    for p in parts:
        for it in loaded[p][0]:
            if it["kind"] == "table" and it["key"].startswith("ref."):
                ref_defs[it["key"]] = merge_columns(ref_defs[it["key"]], it["sql"]) if it["key"] in ref_defs else it["sql"]

    def owner_of(ref_name):
        base = ref_name.split(".", 1)[1]
        hits = [t for t in owned if t.split(".")[1] == base]
        return hits[0] if len(hits) == 1 else None

    def part_title(p):
        return re.search(r"Service\s*:\s*(.+)", loaded[p][1]).group(1).strip()

    out, emitted, views, fks, stats = [], set(), [], [], {"owned": 0, "ref": 0, "shared": 0}
    out.append(f"-- Run once as an admin, then connect to the new database and run the rest of this script:\n"
               f"--   CREATE DATABASE {database} ENCODING 'UTF8' TEMPLATE template0;\n--   \\c {database}\n\n")
    head = [f"/* {RULE}", f"   DR REDDIS HEALTHCARE - HIMS CONSOLIDATED MICROSERVICE DATABASE (database_v2)",
            f"   Service      : {file[:2]}. {title}", f"   Database     : {database}   (PostgreSQL 15+)",
            f"   Replaces     : " + ", ".join(f"{p[3:]} ({p}.sql)" for p in parts),
            f"   Generated by : tools/gen_database_v2.py from the scripts in database/ - edit the generator or the source scripts, not this file.",
            f"   {'-' * 85}"]
    if len(parts) > 1:
        head += ["   Consolidation:",
                 "     - Owned tables of every part are unchanged (same schema, table and column names), so each part's code keeps working.",
                 "     - core.number_sequence, the evt.* tables and the util functions are created once for the whole service.",
                 "     - ref.* replicas that several parts had are created once.",
                 "     - ref.* replicas of tables another part of this service owns are read-only VIEWS of the owner table.",
                 "     - 'logical FK' columns that point to a table now owned by this service are real foreign keys.",
                 "     - evt.inbox is keyed by message id: the parts run as ONE consumer (one process / one queue) for this database."]
    head += [f"   Part headers from the source scripts follow each PART banner below.", f"   {RULE} */", ""]
    out.append("\n".join(head) + "\n")

    # schemas: union, in first-seen order (util is created with the housekeeping functions at the end)
    out.append("/* ---------- SCHEMAS ---------- */\n\n")
    for p in parts:
        for it in loaded[p][0]:
            if it["kind"] == "schema" and it["key"] != "util" and ("schema", it["key"]) not in emitted:
                emitted.add(("schema", it["key"]))
                out.append(f"CREATE SCHEMA {it['key']};\n\n")
    out.append("CREATE SCHEMA util;\n\n")
    out.append("-- Rejects writes to the read-only ref.* views (they are kept in step by the owner table itself).\n"
               "CREATE FUNCTION util.reject_write() RETURNS trigger\nLANGUAGE plpgsql AS $$\nBEGIN\n"
               "    RAISE EXCEPTION '% is a read-only view of a table owned by this service; write to the owner table instead', TG_TABLE_NAME;\n"
               "END $$;\n\n")

    for p in parts:
        items, header = loaded[p]
        out.append(f"/* {RULE}\n   PART: {part_title(p)}   (from database/{p}.sql)\n   {RULE} */\n\n")
        if len(parts) > 1:
            out.append(header + "\n\n")
        skip_table = None
        for it in items:
            kind, key, comment, sql = it["kind"], it["key"], it["comment"], it["sql"]
            if kind in ("schema", "housekeeping"):
                continue
            # cross-service reference comments that are now inside this service
            comment = re.sub(r"(?m)^-- (\w+\.\w+\.\w+) -> (\w+\.\w+) \[[^\]]+\]$",
                             lambda m: f"-- {m.group(1)} -> {m.group(2)}  [same service now: enforced by a foreign key]"
                             if m.group(2) in owned and owned[m.group(2)][0] != p else m.group(0), comment)
            if kind == "comment":
                if "POSTGRESQL HOUSEKEEPING" not in sql:
                    out.append(comment + sql.rstrip() + "\n\n")
                continue
            if kind == "index":
                if ("index", sql.strip()) in emitted or key == skip_table:
                    continue
                emitted.add(("index", sql.strip()))
                out.append(comment + sql.rstrip() + "\n\n")
                continue
            # tables
            if key in SHARED_INFRA or (key.startswith("ref.") and not owner_of(key)):
                if ("table", key) in emitted:
                    out.append(f"-- {key}: created above (shared by the whole service).\n\n")
                    skip_table = key
                    continue
                emitted.add(("table", key))
                skip_table = None
                stats["shared" if key in SHARED_INFRA else "ref"] += 1
                if key.startswith("ref."):
                    sql = ref_defs[key]
                out.append(comment + sql.rstrip() + "\n\n")
                continue
            if key.startswith("ref."):   # replica of a table owned by another part of this service -> view
                owner = owner_of(key)
                if ("view", key) in emitted:
                    continue
                emitted.add(("view", key))
                views.append(key)
                out.append(comment + view_for(sql, key, owner, owned[owner][1], part_title(owned[owner][0])) + "\n")
                skip_table = key
                continue
            # owned table: logical FKs to tables of an earlier part of this service become real foreign keys
            skip_table = None
            stats["owned"] += 1

            def to_fk(m):   # groups: definition up to NULL, comma, spacing, target table
                definition, comma, spacing, target = m.groups()
                if target not in owned or owned[target][0] == p:
                    return m.group(0)
                fks.append(f"{key}.{definition.split()[0]} -> {target}")
                return f"{definition} REFERENCES {target}({pk_column(owned[target][1])}){comma}{spacing}-- FK -> {target} [same service now]"
            sql = re.sub(r"(?m)^(\s+\w+\s+[^\n]*?\bNULL)(,?)(\s+)--\s*logical FK -> (\w+\.\w+) \[[^\]]+\]", to_fk, sql)
            out.append(comment + sql.rstrip() + "\n\n")
        if p in EXTENSIONS:
            ext = (SRC / "extensions" / EXTENSIONS[p]).read_text(encoding="utf-8")
            out.append(f"/* ---------- EXTENSIONS (from database/extensions/{EXTENSIONS[p]}) ---------- */\n\n{ext.strip()}\n\n")

    # housekeeping once, attaching the row_ver trigger to base tables only (the ref views have row_ver-derived columns)
    hk = (SRC / f"{parts[0]}.sql").read_text(encoding="utf-8")
    hk = hk[hk.index("/* ====", hk.index("POSTGRESQL HOUSEKEEPING") - 200):]
    hk = hk.replace("CREATE SCHEMA IF NOT EXISTS util;\n\n", "")
    hk = hk.replace("         WHERE c.column_name = 'row_ver'\n",
                    "          JOIN information_schema.tables t ON t.table_schema = c.table_schema AND t.table_name = c.table_name\n"
                    "         WHERE c.column_name = 'row_ver' AND t.table_type = 'BASE TABLE'\n")
    assert "t.table_type = 'BASE TABLE'" in hk, "housekeeping block changed - update the generator"
    out.append(hk.strip() + "\n")

    (OUT / f"{file}.sql").write_text("".join(out), encoding="utf-8", newline="\n")
    return stats, views, fks


if __name__ == "__main__":
    OUT.mkdir(exist_ok=True)
    (OUT / "seed").mkdir(exist_ok=True)
    for file, database, title, parts in SERVICES:
        stats, views, fks = generate(file, database, title, parts)
        print(f"{file}.sql  {database}: {stats['owned']} owned, {stats['ref']} ref tables, {stats['shared']} infra, "
              f"{len(views)} ref views {views}, {len(fks)} new FKs")
    for src, dst in SEEDS.items():
        seed = (SRC / "seed" / f"{src}.seed.sql").read_text(encoding="utf-8")
        (OUT / "seed" / f"{dst}.seed.sql").write_text(seed, encoding="utf-8", newline="\n")

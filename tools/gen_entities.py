#!/usr/bin/env python3
"""
Generates C# EF Core entities + DbContext for every table found in the
database/*.sql scripts (the Dr Reddis data model, used exactly as supplied).

    python tools/gen_entities.py

Output, per .NET service:  services/<slug>/Data/Entities.g.cs
                           services/<slug>/Data/<Ns>DbContext.g.cs
The integration service (11) is Python, so no C# is generated for it.

Nothing here edits the SQL. Re-run it whenever the SQL changes.
"""
import re, sys, json, pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
SQL_DIR = ROOT / "database"
EXT_DIR = SQL_DIR / "extensions"

# number, sql file stem, slug, C# namespace part, port
SERVICES = [
    ("01", "01_patient_access",      "patient-access",      "PatientAccess",      5001),
    ("02", "02_clinical_care",       "clinical-care",       "ClinicalCare",       5002),
    ("03", "03_laboratory",          "laboratory",          "Laboratory",         5003),
    ("04", "04_imaging",             "imaging",             "Imaging",            5004),
    ("05", "05_pharmacy_supply",     "pharmacy-supply",     "PharmacySupply",     5005),
    ("06", "06_revenue_cycle",       "revenue-cycle",       "RevenueCycle",       5006),
    ("07", "07_digital_engagement",  "digital-engagement",  "DigitalEngagement",  5007),
    ("08", "08_field_ops",           "field-ops",           "FieldOps",           5008),
    ("09", "09_hospital_ops",        "hospital-ops",        "HospitalOps",        5009),
    ("10", "10_identity_org",        "identity-org",        "IdentityOrg",        5010),
    ("11", "11_integration",         "integration",         None,                 5011),  # Python
    ("12", "12_comms_docs",          "comms-docs",          "CommsDocs",          5012),
    ("13", "13_back_office",         "back-office",         "BackOffice",         5013),
]

TYPE_MAP = {
    "BIGINT": "long", "INT": "int", "INTEGER": "int", "SMALLINT": "short",
    "BOOLEAN": "bool", "VARCHAR": "string", "CHAR": "string", "TEXT": "string",
    "DECIMAL": "decimal", "NUMERIC": "decimal", "TIMESTAMPTZ": "DateTime",
    "DATE": "DateOnly", "TIME": "TimeOnly", "UUID": "Guid", "JSONB": "string",
}
NUMERIC = {"long", "int", "short", "decimal"}


def pascal(s):
    return "".join(p[:1].upper() + p[1:] for p in s.split("_") if p)


def plural(name):
    if name.endswith("sis"):
        return name[:-3] + "ses"          # Diagnosis -> Diagnoses
    if name.endswith("y") and name[-2:-1] not in "aeiou":
        return name[:-1] + "ies"
    if name.endswith(("s", "x", "ch", "sh")):
        return name + "es"
    return name + "s"


def split_top(body):
    out, depth, cur, q = [], 0, [], False
    for ch in body:
        if ch == "'":
            q = not q
        if not q:
            if ch == "(":
                depth += 1
            elif ch == ")":
                depth -= 1
            elif ch == "," and depth == 0:
                out.append("".join(cur)); cur = []; continue
        cur.append(ch)
    if "".join(cur).strip():
        out.append("".join(cur))
    return out


def parse_default(rest):
    """returns raw default expression string or None (identity handled before)."""
    m = re.search(r"\bDEFAULT\s+", rest)
    if not m:
        return None
    s = rest[m.end():]
    if s.startswith("("):
        depth, i = 0, 0
        for i, ch in enumerate(s):
            if ch == "(":
                depth += 1
            elif ch == ")":
                depth -= 1
                if depth == 0:
                    break
        return s[: i + 1]
    m2 = re.match(r"('(?:[^']|'')*'|[A-Za-z_][A-Za-z_0-9]*\(\)|[A-Za-z_]+|-?[0-9.]+)", s)
    return m2.group(1) if m2 else None


def csharp_default(expr, cstype):
    """(initializer or None, needs_sql_fallback)"""
    if expr is None:
        return None, False
    e = expr.strip()
    while e.startswith("(") and e.endswith(")"):
        e = e[1:-1].strip()
    u = e.upper()
    if u in ("TRUE", "FALSE") and cstype == "bool":
        return u.lower(), False
    if re.fullmatch(r"-?[0-9]+(\.[0-9]+)?", e) and cstype in NUMERIC:
        return (e + "m" if cstype == "decimal" else e), False
    if re.fullmatch(r"'(?:[^']|'')*'", e) and cstype == "string":
        return '"' + e[1:-1].replace("''", "'").replace('"', '\\"') + '"', False
    if u in ("CURRENT_TIMESTAMP", "NOW()") and cstype == "DateTime":
        return "DateTime.UtcNow", False
    if u in ("CURRENT_DATE",) and cstype == "DateOnly":
        return "DateOnly.FromDateTime(DateTime.UtcNow)", False
    if u == "GEN_RANDOM_UUID()" and cstype == "Guid":
        return "Guid.NewGuid()", False
    return None, True


def parse_sql(path):
    text = path.read_text()
    tables = []
    for m in re.finditer(r"CREATE TABLE (\w+)\.(\w+) \((.*?)\n\);", text, re.S):
        schema, table, body = m.group(1), m.group(2), m.group(3)
        body = "\n".join(re.sub(r"--.*", "", l) for l in body.split("\n"))
        cols, uniques = [], []
        for item in split_top(body):
            it = re.sub(r"\s+", " ", item.strip())
            if not it:
                continue
            if re.match(r"^(CONSTRAINT|PRIMARY KEY|UNIQUE|FOREIGN KEY|CHECK|EXCLUDE)\b", it, re.I):
                continue
            mm = re.match(r"^(\w+) ([A-Za-z]+)(?:\((\d+)(?:,(\d+))?\))?(\[\])? ?(.*)$", it)
            if not mm:
                raise SystemExit(f"cannot parse column in {schema}.{table}: {it}")
            name, sqltype, rest = mm.group(1), mm.group(2).upper(), mm.group(6)
            identity = "GENERATED BY DEFAULT AS IDENTITY" in rest or "GENERATED ALWAYS AS IDENTITY" in rest
            computed = bool(re.search(r"GENERATED ALWAYS AS \(", rest))
            rest_nodef = rest.replace("GENERATED BY DEFAULT AS IDENTITY", "")
            pk = "PRIMARY KEY" in rest
            notnull = "NOT NULL" in rest or pk
            default = None if computed else parse_default(rest_nodef)
            cols.append(dict(name=name, sqltype=sqltype, notnull=notnull, pk=pk,
                             identity=identity, computed=computed, default=default))
        tables.append(dict(schema=schema, table=table, cols=cols))
    return tables


def apply_extensions(tables, stem):
    """Adds columns from database/extensions/<stem>.ext.sql (ALTER TABLE .. ADD COLUMN) to the parsed tables."""
    ext = EXT_DIR / f"{stem}.ext.sql"
    if not ext.exists():
        return 0
    by = {(t["schema"], t["table"]): t for t in tables}
    n = 0
    for m in re.finditer(r"ALTER TABLE (\w+)\.(\w+)\s+ADD COLUMN IF NOT EXISTS (\w+)\s+([A-Za-z]+)(?:\(\d+(?:,\d+)?\))?\s*(NOT NULL|NULL)?", ext.read_text()):
        schema, table, col, typ, nul = m.groups()
        t = by[(schema, table)]
        t["cols"].append(dict(name=col, sqltype=typ.upper(), notnull=(nul == "NOT NULL"), pk=False,
                              identity=False, computed=False, default=None, extension=True))
        n += 1
    return n


def entity_names(tables):
    base = {}
    for t in tables:
        base.setdefault(pascal(t["table"]), []).append(t)
    names = {}
    for t in tables:
        b = pascal(t["table"])
        if t["schema"] in ("ref", "evt"):
            n = pascal(t["schema"]) + b
        elif len(base[b]) > 1:
            n = pascal(t["schema"]) + b
        else:
            n = b
        names[(t["schema"], t["table"])] = n
    return names


def gen_service(num, stem, slug, ns):
    tables = parse_sql(SQL_DIR / f"{stem}.sql")
    n_ext = apply_extensions(tables, stem)
    names = entity_names(tables)
    out = ROOT / "services" / slug / "Data"
    out.mkdir(parents=True, exist_ok=True)
    fallback = []  # (entity, prop, sql)
    L = [
        "// <auto-generated>",
        f"// Generated by tools/gen_entities.py from database/{stem}.sql. DO NOT EDIT.",
        "// One class per table, named exactly as in the data model. Re-run the tool after any SQL change.",
        "// </auto-generated>",
        "#nullable enable",
        "using System;",
        "using System.ComponentModel.DataAnnotations;",
        "using System.ComponentModel.DataAnnotations.Schema;",
        "",
        f"namespace Hims.{ns}.Data;",
        "",
    ]
    dbsets = []
    meta = {}
    for t in tables:
        cls = names[(t["schema"], t["table"])]
        L.append(f'/// <summary>Table <c>{t["schema"]}.{t["table"]}</c></summary>')
        L.append(f'[Table("{t["table"]}", Schema = "{t["schema"]}")]')
        L.append(f"public class {cls}")
        L.append("{")
        props = []
        for c in t["cols"]:
            cs = TYPE_MAP[c["sqltype"]]
            prop = pascal(c["name"])
            if prop == cls:
                prop += "Value"
            init, need_sql = csharp_default(c["default"], cs)
            nullable = not c["notnull"]
            typ = cs + ("?" if nullable else "")
            attrs = []
            if c["pk"]:
                attrs.append("Key")
                attrs.append("DatabaseGenerated(DatabaseGeneratedOption.%s)" % ("Identity" if c["identity"] else "None"))
            elif c["computed"]:
                attrs.append("DatabaseGenerated(DatabaseGeneratedOption.Computed)")
            col = f'Column("{c["name"]}"' + (', TypeName = "jsonb"' if c["sqltype"] == "JSONB" else "") + ")"
            attrs.append(col)
            comment = "    /// <summary>Extension column (database/extensions), not in the original script.</summary>\n" if c.get("extension") else ""
            line = f'{comment}    [{", ".join(attrs)}]\n    public {typ} {prop} {{ get; set; }}'
            if not nullable and cs == "string":
                line += " = string.Empty;"
            elif init and not c["identity"] and not c["computed"] and not c["pk"]:
                line += f" = {init};"
            if need_sql and c["default"] and not c["identity"] and not c["computed"]:
                fallback.append((cls, prop, c["default"]))
            L.append(line)
            props.append((c["name"], prop, cs, nullable, c["pk"], c["identity"]))
        L.append("}")
        L.append("")
        dbsets.append((cls, plural(cls)))
        meta[cls] = dict(table=f'{t["schema"]}.{t["table"]}', props=[dict(col=p[0], prop=p[1], type=p[2], null=p[3], pk=p[4], identity=p[5]) for p in props])
    (out / "Entities.g.cs").write_text("\n".join(L))

    ctx = f"{ns}DbContext"
    D = [
        "// <auto-generated> Generated by tools/gen_entities.py. DO NOT EDIT. </auto-generated>",
        "#nullable enable",
        "using Microsoft.EntityFrameworkCore;",
        "",
        f"namespace Hims.{ns}.Data;",
        "",
        f"/// <summary>EF Core context over the <c>hims_{stem.split('_',1)[1]}</c> database: every table of {stem}.sql is mapped.</summary>",
        f"public partial class {ctx} : DbContext",
        "{",
        f"    public {ctx}(DbContextOptions<{ctx}> options) : base(options) {{ }}",
        "",
    ]
    for cls, pl in dbsets:
        D.append(f"    public DbSet<{cls}> {pl} => Set<{cls}>();")
    D += ["", "    protected override void OnModelCreating(ModelBuilder modelBuilder)", "    {"]
    for cls, prop, sql in fallback:
        sqlq = sql.replace('"', '\\"')
        D.append(f'        modelBuilder.Entity<{cls}>().Property(e => e.{prop}).HasDefaultValueSql("{sqlq}");')
    D += ["        base.OnModelCreating(modelBuilder);", "    }", "}", ""]
    (out / f"{ctx}.g.cs").write_text("\n".join(D))

    ob = names[("evt", "outbox")]
    OB = f"""// <auto-generated> Generated by tools/gen_entities.py. DO NOT EDIT. </auto-generated>
#nullable enable
using Hims.Common.Events;

namespace Hims.{ns}.Data;

/// <summary>
/// Transactional outbox helper. Call <c>db.EnqueueEvent(...)</c> in the same unit of work as the business change and
/// then <c>SaveChangesAsync()</c>: the domain rows and the <c>evt.outbox</c> row commit together, and the OutboxRelay
/// (Hims.Common) later publishes the row to RabbitMQ.
/// </summary>
public static class {ns}OutboxExtensions
{{
    public static {ob} EnqueueEvent(this {ctx} db, string eventType, string aggregateType, long aggregateId, object payload,
        int? organizationId = null, int? branchId = null, long? patientId = null, Guid? correlationId = null)
    {{
        var row = new {ob}
        {{
            EventType = eventType,
            AggregateType = aggregateType,
            AggregateId = aggregateId,
            SessionKey = (patientId ?? aggregateId).ToString(),
            OrganizationId = organizationId,
            BranchId = branchId,
            PatientId = patientId,
            CorrelationId = correlationId,
            PayloadJson = EventJson.Serialize(payload),
        }};
        db.{plural(ob)}.Add(row);
        return row;
    }}
}}
"""
    (out / f"{ns}OutboxExtensions.g.cs").write_text(OB)
    return len(tables), fallback, meta, names


if __name__ == "__main__":
    all_meta = {}
    for num, stem, slug, ns, port in SERVICES:
        if ns is None:
            n = len(parse_sql(SQL_DIR / f"{stem}.sql"))
            print(f"{num} {slug:20s} tables={n:3d}  (python service, no C# generated)")
            continue
        n, fb, meta, names = gen_service(num, stem, slug, ns)
        all_meta[slug] = meta
        print(f"{num} {slug:20s} tables={n:3d}  sql-default fallbacks={len(fb)}")
        for f in fb[:6]:
            print("     fallback:", f)
    (ROOT / "tools" / "entity_meta.json").write_text(json.dumps(all_meta, indent=1))

# HIMS Database Backup & Restore

Scripts to back up and restore the HIMS PostgreSQL databases (server `103.169.179.22:50085`).

Run everything below from **Git Bash** (not Command Prompt / PowerShell/ cmd.exe) — these are bash scripts.

## Requirements

- PostgreSQL **18.x client tools** on your machine (matching the server version). Having PostgreSQL 15/17 installed elsewhere is fine — just point the scripts at the 18 binaries explicitly, as shown below.
- Network access to `103.169.179.22:50085`.
- The `hims` database password.

---

## Backup — all databases

Dumps every `hims_*` database on the server into a timestamped folder under `database/backup/dumps/`, plus a `globals.sql` file with role/tablespace definitions.

```bash
cd database/backup
PGPASSWORD=your_password \
PG_DUMP_BIN="/C/Program Files/PostgreSQL/18/bin/pg_dump.exe" \
PG_DUMPALL_BIN="/C/Program Files/PostgreSQL/18/bin/pg_dumpall.exe" \
./backup_all.sh
```

**Output:** `dumps/<YYYYMMDD_HHMMSS>/`
- One `<database_name>.dump` file per database (compressed, `pg_restore`-compatible custom format)
- `globals.sql` — roles and tablespaces (no passwords — see note below)
- `backup.log` — full log of the run

**Notes:**
- Replace `your_password` with the actual `hims` database password.
- `PG_DUMP_BIN` / `PG_DUMPALL_BIN` must point at PostgreSQL **18.x** binaries — using an older client (15/17) against the 18.6 server will fail with a version-mismatch error.
- Adjust the PostgreSQL install path if yours differs (check with `ls "/c/Program Files/PostgreSQL/"`).
- Old backup folders older than 14 days are pruned automatically on each run (override with `RETENTION_DAYS=0 ./backup_all.sh` to disable).

---

## Restore — a single database

Restores one database from a `.dump` file produced by `backup_all.sh`. **This drops and recreates the target database** — anything currently in it is lost.

```bash
cd database/backup
PGPASSWORD=your_password \
PSQL_BIN="/c/Program Files/PostgreSQL/18/bin/psql.exe" \
PG_RESTORE_BIN="/c/Program Files/PostgreSQL/18/bin/pg_restore.exe" \
./restore_one.sh dumps/20261008_124819/hims_patient_access.dump hims_patient_access_restore
```

**Arguments:**
1. Path to the `.dump` file to restore from
2. Target database name — use the original name (e.g. `hims_patient_access`) to restore in place, or a different name (e.g. `hims_patient_access_restore`) to restore into a new, separate database for inspection without touching the live one

**What it does:**
1. Prompts for confirmation (`y` to proceed)
2. Drops the target database if it exists (force-closes any other active connections first, so a stray pgAdmin/DBeaver session won't block it)
3. Recreates it, owned by the `hims` role
4. Restores the data with `pg_restore` (parallelized, 4 jobs)

**Before restoring over a live database:** stop any service that connects to it (e.g. the matching .NET microservice, or the Python Integration Hub for `hims_integration`), so nothing is actively using it mid-restore.

---

## Restoring `globals.sql` (roles/tablespaces)

Not handled by `restore_one.sh` — it's plain SQL, applied separately:

```bash
"/c/Program Files/PostgreSQL/18/bin/psql.exe" -h 103.169.179.22 -p 50085 -U hims -d postgres -f dumps/<timestamp>/globals.sql
```

Role passwords are **not** included in `globals.sql` (dumped with `--no-role-passwords`, since reading password hashes requires superuser). Reset passwords manually after restoring roles if needed.

---

## Quick reference

| Task | Command |
|---|---|
| Back up all databases | `./backup_all.sh` (with `PG_DUMP_BIN` / `PG_DUMPALL_BIN` set) |
| Restore one database | `./restore_one.sh <dump_file> <target_db_name>` (with `PSQL_BIN` / `PG_RESTORE_BIN` set) |
| Check which PostgreSQL versions are installed | `ls "/c/Program Files/PostgreSQL/"` |
| See who's connected to a database | `psql -h 103.169.179.22 -p 50085 -U hims -d postgres -c "SELECT pid, usename, application_name, client_addr, state FROM pg_stat_activity WHERE datname = '<db_name>';"` |
#!/usr/bin/env bash
#
# restore_one.sh — Restore a single database from a .dump file created by backup_all.sh
#
# Usage:
#   ./restore_one.sh <dump_file> <target_db_name>
#
# Example:
#   ./restore_one.sh dumps/20261007_152500/hims_laboratory.dump hims_laboratory
#
# WARNING: this drops and recreates the target database before restoring.

set -euo pipefail

PGHOST="${PGHOST:-103.169.179.22}"
PGPORT="${PGPORT:-50085}"
PGUSER="${PGUSER:-hims}"

# Override these if your PATH points at the wrong major version, e.g. on
# Windows with multiple PostgreSQL installs — use the SAME major version
# as the server (18.x) to avoid client/server version-mismatch errors:
#   PSQL_BIN="/c/Program Files/PostgreSQL/18/bin/psql.exe"
#   PG_RESTORE_BIN="/c/Program Files/PostgreSQL/18/bin/pg_restore.exe"
PSQL_BIN="${PSQL_BIN:-psql}"
PG_RESTORE_BIN="${PG_RESTORE_BIN:-pg_restore}"

DUMP_FILE="${1:?Usage: $0 <dump_file> <target_db_name>}"
TARGET_DB="${2:?Usage: $0 <dump_file> <target_db_name>}"

if [ ! -f "${DUMP_FILE}" ]; then
    echo "Dump file not found: ${DUMP_FILE}" >&2
    exit 1
fi

export PGHOST PGPORT PGUSER

read -r -p "This will DROP and recreate '${TARGET_DB}' on ${PGHOST}:${PGPORT}. Continue? [y/N] " CONFIRM
if [[ ! "${CONFIRM}" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

echo "Dropping database ${TARGET_DB} (if exists)..."
"${PSQL_BIN}" -h "${PGHOST}" -p "${PGPORT}" -U "${PGUSER}" -d postgres -c "DROP DATABASE IF EXISTS \"${TARGET_DB}\";"

echo "Creating database ${TARGET_DB}..."
"${PSQL_BIN}" -h "${PGHOST}" -p "${PGPORT}" -U "${PGUSER}" -d postgres -c "CREATE DATABASE \"${TARGET_DB}\" OWNER ${PGUSER};"

echo "Restoring from ${DUMP_FILE}..."
"${PG_RESTORE_BIN}" -h "${PGHOST}" -p "${PGPORT}" -U "${PGUSER}" -d "${TARGET_DB}" \
    --no-owner --no-privileges -j 4 "${DUMP_FILE}"

echo "Restore complete: ${TARGET_DB}"
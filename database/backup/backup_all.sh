#!/usr/bin/env bash
#
# backup_all.sh — Dump every hims_* PostgreSQL database to a timestamped folder.
#
# Usage:
#   ./backup_all.sh                    # backup all hims_* databases
#   PGPASSWORD=xxx ./backup_all.sh      # pass password via env instead of prompt
#
# Config can be overridden via environment variables, e.g.:
#   PGHOST=103.169.179.22 PGPORT=50085 PGUSER=hims BACKUP_DIR=/mnt/backups ./backup_all.sh

set -euo pipefail

# ---- Config (override via env) ------------------------------------------
PGHOST="${PGHOST:-103.169.179.22}"
PGPORT="${PGPORT:-50085}"
PGUSER="${PGUSER:-hims}"
BACKUP_ROOT="${BACKUP_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/dumps}"
RETENTION_DAYS="${RETENTION_DAYS:-14}"   # set to 0 to disable pruning
DB_PATTERN="${DB_PATTERN:-hims_%}"       # SQL LIKE pattern for db discovery

# Override these if your PATH points at the wrong major version, e.g. on
# Windows with multiple PostgreSQL installs:
#   PG_DUMP_BIN="/c/Program Files/PostgreSQL/18/bin/pg_dump.exe"
#   PG_DUMPALL_BIN="/c/Program Files/PostgreSQL/18/bin/pg_dumpall.exe"
PG_DUMP_BIN="${PG_DUMP_BIN:-pg_dump}"
PG_DUMPALL_BIN="${PG_DUMPALL_BIN:-pg_dumpall}"

export PGHOST PGPORT PGUSER

TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
DEST_DIR="${BACKUP_ROOT}/${TIMESTAMP}"
LOG_FILE="${DEST_DIR}/backup.log"

mkdir -p "${DEST_DIR}"
if [ ! -d "${DEST_DIR}" ]; then
    echo "FATAL: could not create destination directory: ${DEST_DIR}" >&2
    exit 1
fi

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "${LOG_FILE}"
}

log "=== HIMS database backup started ==="
log "Host: ${PGHOST}:${PGPORT}  User: ${PGUSER}"
log "Destination: ${DEST_DIR}"
log "pg_dump: ${PG_DUMP_BIN}   pg_dumpall: ${PG_DUMPALL_BIN}"

# Work from inside the destination folder. We deliberately do NOT pass -f to
# pg_dump/pg_dumpall below — on Git Bash / Windows, a native pg_dump.exe can
# fail to open a file via its own -f argument ("No such file or directory")
# even when the directory genuinely exists, due to how Windows path/cwd
# translation interacts with natively-spawned processes. Instead we let
# pg_dump write to STDOUT and use bash's own ">" redirection to create the
# file — bash's redirection is reliable here (it's what writes backup.log).
cd "${DEST_DIR}"

# ---- Discover databases ---------------------------------------------------
mapfile -t DATABASES < <(
    psql -h "${PGHOST}" -p "${PGPORT}" -U "${PGUSER}" -d postgres -Atq -c \
        "SELECT datname FROM pg_database WHERE datname LIKE '${DB_PATTERN}' AND datistemplate = false ORDER BY datname;" \
        | tr -d '\r'
)
# Defensive: strip any stray \r / trailing whitespace from each entry too
# (Windows psql output is CRLF; a stray \r here silently corrupts the dbname
# passed to pg_dump, producing "database ... does not exist" errors, and
# also garbles terminal output by moving the cursor without a newline).
for i in "${!DATABASES[@]}"; do
    DATABASES[$i]="$(printf '%s' "${DATABASES[$i]}" | tr -d '\r' | sed 's/[[:space:]]*$//')"
done

if [ "${#DATABASES[@]}" -eq 0 ]; then
    log "No databases matched pattern '${DB_PATTERN}'. Nothing to back up."
    exit 1
fi

log "Found ${#DATABASES[@]} database(s): ${DATABASES[*]}"

FAILED=()

# ---- Dump each database ----------------------------------------------------
for DB in "${DATABASES[@]}"; do
    OUT_FILE="${DB}.dump"   # relative — we already cd'd into DEST_DIR
    log "Backing up ${DB} -> ${DEST_DIR}/${OUT_FILE}"

    if "${PG_DUMP_BIN}" -h "${PGHOST}" -p "${PGPORT}" -U "${PGUSER}" \
        -F custom -Z 9 --no-owner --no-privileges \
        "${DB}" > "${OUT_FILE}" 2>>"${LOG_FILE}"; then
        SIZE="$(du -h "${OUT_FILE}" | cut -f1)"
        log "  OK (${SIZE})"
    else
        log "  FAILED: see ${LOG_FILE} for details"
        rm -f "${OUT_FILE}"   # remove partial/empty file so it's not mistaken for a valid backup
        FAILED+=("${DB}")
    fi
done

# ---- Also dump global objects (roles, tablespaces) -------------------------
GLOBALS_FILE="globals.sql"   # relative — still inside DEST_DIR
log "Backing up global objects (roles/tablespaces) -> ${DEST_DIR}/${GLOBALS_FILE}"
if "${PG_DUMPALL_BIN}" -h "${PGHOST}" -p "${PGPORT}" -U "${PGUSER}" \
    --globals-only --no-role-passwords > "${GLOBALS_FILE}" 2>>"${LOG_FILE}"; then
    log "  OK"
else
    log "  FAILED: globals dump — see ${LOG_FILE} for the exact server error"
    log "  (common causes: client/server version mismatch — see PG_DUMPALL_BIN above —"
    log "  or insufficient privileges on the connecting role)"
    rm -f "${GLOBALS_FILE}"
    FAILED+=("globals")
fi

# ---- Prune old backups ------------------------------------------------------
if [ "${RETENTION_DAYS}" -gt 0 ]; then
    log "Pruning backups older than ${RETENTION_DAYS} day(s) in ${BACKUP_ROOT}"
    find "${BACKUP_ROOT}" -mindepth 1 -maxdepth 1 -type d -mtime "+${RETENTION_DAYS}" -print -exec rm -rf {} \; | tee -a "${LOG_FILE}"
fi

# ---- Summary ----------------------------------------------------------------
if [ "${#FAILED[@]}" -eq 0 ]; then
    log "=== Backup completed successfully: ${#DATABASES[@]} database(s) + globals ==="
    exit 0
else
    log "=== Backup completed WITH ERRORS. Failed: ${FAILED[*]} ==="
    exit 1
fi
#!/usr/bin/env bash
# Creates one PostgreSQL database per microservice and loads, in order:
#   1. the ORIGINAL data-model script, exactly as supplied (never edited)
#   2. extensions/<name>.ext.sql  - extra columns we added (only where needed)
#   3. seed/<name>.seed.sql       - minimal reference data so the workflow can run
# Deployment order follows the data-model README: 10 (identity) first, then 06 and 05, then the rest.
# Safe to re-run: a script that was already applied is skipped.
#
#   PGHOST=localhost PGUSER=hims PGPassword=xv7o4aPKUqR6oEf5 ./deploy.sh
set -euo pipefail
cd "$(dirname "$0")"
export PGHOST="${PGHOST:-localhost}" PGPORT="${PGPORT:-5432}" PGUSER="${PGUSER:-hims}"
ORDER="10_identity_org 06_revenue_cycle 05_pharmacy_supply 01_patient_access 02_clinical_care 03_laboratory 04_imaging 07_digital_engagement 08_field_ops 09_hospital_ops 11_integration 12_comms_docs 13_back_office"
for name in $ORDER; do
  db="hims_${name#*_}"
  if ! psql -d postgres -Atqc "select 1 from pg_database where datname='$db'" | grep -q 1; then
    createdb -E UTF8 -T template0 "$db"; echo "created database $db"
  fi
  if [ "$(psql -d "$db" -Atqc "select to_regclass('evt.outbox') is not null")" = "t" ]; then
    echo "[$db] data model already applied - skipping ${name}.sql"
  else
    echo "[$db] applying ${name}.sql"; psql -v ON_ERROR_STOP=1 -q -d "$db" -f "${name}.sql"
  fi
  [ -f "extensions/${name}.ext.sql" ]  && { echo "[$db] applying extension"; psql -v ON_ERROR_STOP=1 -q -d "$db" -f "extensions/${name}.ext.sql"; }
  [ -f "seed/${name}.seed.sql" ]       && { echo "[$db] applying seed";      psql -v ON_ERROR_STOP=1 -q -d "$db" -f "seed/${name}.seed.sql" >/dev/null; }
done
echo "done."

#!/usr/bin/env bash
# Onboards a new tenant (hospital group) on the database_v3 model: its own PostgreSQL database, its organization, and the
# OrganizationUpdated event that tells the other microservices about it over RabbitMQ.
#
#   ./tenant.sh database  <db options>                    create the tenant database and load the 7 service schemas (database_v3/)
#   ./tenant.sh tenant    <db options> <tenant options>   create the organization and sync it to the other services
#   ./tenant.sh all       <db options> <tenant options>   both (default)
#
# Database connection:
#   --db-host HOST          (default localhost)          --db-port PORT        (default 5432)
#   --db-user USER          (default hims; needs CREATEDB the first time)
#   --db-password PASS      (or PGPASSWORD)              --db-name NAME        (default hims_<tenant>)
#   --app-db-password PASS  password of the services' login hims: applies database_v3/roles.sql (optional)
# Tenant:
#   --org-id ID             organization_id, e.g. 3 (the services' "Tenants" config uses the same id)
#   --org-name NAME         e.g. "Care Hospitals"
#   --org-code CODE         core_organization.org_code, e.g. CARE
#   --tenant NAME           tenant name = frontend subdomain = exchange hims.<tenant>.events (default: org code in lower case)
#   --legal-name NAME       (optional)
# RabbitMQ (management HTTP API, port 15672 of the rabbitmq:3.13-management image):
#   --mq-url URL            (default http://localhost:15672)   --mq-user USER (default guest)   --mq-password PASS (default guest)
#   --mq-vhost VHOST        (default /)
#   --services "a b"        services that replicate the organization (default: the ones with AddRefReplica<.., RefOrganization>)
#   --no-publish            only write the outbox row; identity-org's outbox relay publishes it once the tenant is in its config
#
# Example:
#   ./tenant.sh all --db-host 103.169.179.22 --db-port 50085 --db-user hims --db-password '...' \
#       --org-id 3 --org-name "Care Hospitals" --org-code CARE --tenant care \
#       --mq-url http://103.169.179.22:15672 --mq-user hims --mq-password '...'
#
# How the sync works: the organization and an OrganizationUpdated row in identity_org.evt_outbox are written in one transaction
# (as POST /api/admin/republish does). The event is then published to hims.<tenant>.events with the outbox event_id as message
# id, and the row is stamped published_at. Each subscriber's queue <service>.<tenant>.events is declared here (same arguments
# as EventConsumer), so the event waits in it until that service runs with the new tenant in its configuration:
#   "ConnectionStrings": { "<tenant>": "...Database=<db-name>..." },  "Tenants": [ ..., { "Name": "<tenant>", "OrganizationId": <org-id> } ]
# A second delivery (the relay, or re-running this script) is ignored by the consumers' evt_inbox, or upserts the same row.
# Safe to re-run: loaded schemas are skipped, an existing organization is updated and announced again.
set -euo pipefail
SELF="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
cd "$(dirname "$0")/../database_v3"

usage() { sed -n '2,/^set -euo/p' "$SELF" | sed '$d; s/^# \{0,1\}//'; exit "${1:-0}"; }
die() { echo "tenant.sh: $*" >&2; exit 1; }

COMMAND=all
case "${1:-}" in database|tenant|all) COMMAND=$1; shift ;; -h|--help) usage ;; esac

DB_HOST=localhost DB_PORT=5432 DB_USER=hims DB_PASSWORD="${PGPASSWORD:-}" DB_NAME="" APP_DB_PASSWORD=""
ORG_ID="" ORG_NAME="" ORG_CODE="" TENANT="" LEGAL_NAME=""
MQ_URL=http://localhost:15672 MQ_USER=guest MQ_PASSWORD=guest MQ_VHOST=/ PUBLISH=1
SERVICES="patient-engagement clinical-care diagnostics revenue-finance"
while [ $# -gt 0 ]; do
  case "$1" in
    --db-host) DB_HOST=$2 ;;        --db-port) DB_PORT=$2 ;;         --db-user) DB_USER=$2 ;;
    --db-password) DB_PASSWORD=$2 ;; --db-name) DB_NAME=$2 ;;        --app-db-password) APP_DB_PASSWORD=$2 ;;
    --org-id) ORG_ID=$2 ;;          --org-name) ORG_NAME=$2 ;;       --org-code) ORG_CODE=$2 ;;
    --tenant) TENANT=$2 ;;          --legal-name) LEGAL_NAME=$2 ;;
    --mq-url) MQ_URL=${2%/} ;;      --mq-user) MQ_USER=$2 ;;         --mq-password) MQ_PASSWORD=$2 ;;
    --mq-vhost) MQ_VHOST=$2 ;;      --services) SERVICES=$2 ;;
    --no-publish) PUBLISH=0; shift; continue ;;
    -h|--help) usage ;;
    *) echo "tenant.sh: unknown option $1" >&2; usage 1 ;;
  esac
  [ $# -ge 2 ] || die "$1 needs a value"
  shift 2
done

TENANT=$(printf '%s' "${TENANT:-$ORG_CODE}" | tr '[:upper:]' '[:lower:]')
[ -n "$DB_NAME" ] || { [ -n "$TENANT" ] || die "give --db-name or --tenant/--org-code"; DB_NAME="hims_$TENANT"; }
[ -n "$DB_PASSWORD" ] || die "give --db-password (password of $DB_USER on $DB_HOST:$DB_PORT)"
if [ "$COMMAND" != database ]; then
  [[ "$ORG_ID" =~ ^[1-9][0-9]*$ ]] || die "--org-id must be a positive number"
  [ -n "$ORG_NAME" ] || die "give --org-name"
  [ -n "$ORG_CODE" ] && [ ${#ORG_CODE} -le 20 ] || die "give --org-code (at most 20 characters)"
  [[ "$TENANT" =~ ^[a-z0-9][a-z0-9-]*$ ]] || die "--tenant must be a subdomain label (a-z, 0-9, -), got '$TENANT'"
fi
export PGHOST="$DB_HOST" PGPORT="$DB_PORT" PGUSER="$DB_USER" PGPASSWORD="$DB_PASSWORD"

# --- 1. database: same steps as database_v3/deploy.sh, without the seeds (they belong to organizations 1 and 2) ---------
create_database() {
  local order="01_identity_org 05_revenue_finance 06_operations_supply 02_patient_engagement 03_clinical_care 04_diagnostics 07_integration_comms"
  if ! psql -d postgres -Atqc "select 1 from pg_database where datname='$DB_NAME'" | grep -q 1; then
    createdb -E UTF8 -T template0 "$DB_NAME"; echo "created database $DB_NAME"
  fi
  for name in $order; do
    schema="${name#*_}"
    if [ "$(psql -d "$DB_NAME" -Atqc "select to_regclass('${schema}.evt_outbox') is not null" | tr -d '\r')" = "t" ]; then
      echo "[$DB_NAME.$schema] already loaded - skipping ${name}.sql"
    else
      echo "[$DB_NAME.$schema] applying ${name}.sql"; psql -v ON_ERROR_STOP=1 -q -d "$DB_NAME" -f "${name}.sql"
    fi
  done
  if [ -n "$APP_DB_PASSWORD" ]; then
    echo "[$DB_NAME] login hims: grants on the service schemas"
    psql -v ON_ERROR_STOP=1 -q -d "$DB_NAME" -v hims_password="$APP_DB_PASSWORD" -f roles.sql >/dev/null
  fi
}

# --- 2. tenant: organization + OrganizationUpdated in the outbox (one transaction), then publish -------------------------
mq() {   # mq METHOD PATH [JSON]: call the RabbitMQ management API, print the response body, fail on HTTP >= 400
  curl -sS --fail-with-body -u "$MQ_USER:$MQ_PASSWORD" -H 'content-type: application/json' -X "$1" "$MQ_URL/api$2" ${3:+--data "$3"}
}

create_tenant() {
  [ "$(psql -d "$DB_NAME" -Atqc "select to_regclass('identity_org.evt_outbox') is not null" | tr -d '\r')" = "t" ] \
    || die "$DB_NAME has no identity_org schema - run ./tenant.sh database first"

  local outbox_id
  outbox_id=$(psql -d "$DB_NAME" -v ON_ERROR_STOP=1 -Atq \
      -v org_id="$ORG_ID" -v org_code="$ORG_CODE" -v org_name="$ORG_NAME" -v legal_name="$LEGAL_NAME" <<'SQL' | tr -d '\r' | tail -n1
BEGIN;
INSERT INTO identity_org.core_organization (organization_id, org_code, org_name, legal_name)
VALUES (:org_id, :'org_code', :'org_name', NULLIF(:'legal_name', ''))
ON CONFLICT (organization_id) DO UPDATE
   SET org_code = EXCLUDED.org_code, org_name = EXCLUDED.org_name,
       legal_name = COALESCE(EXCLUDED.legal_name, identity_org.core_organization.legal_name),
       updated_at = CURRENT_TIMESTAMP, row_ver = identity_org.core_organization.row_ver + 1;
-- explicit id: keep the identity ahead of it
SELECT setval(pg_get_serial_sequence('identity_org.core_organization', 'organization_id'),
              (SELECT max(organization_id) FROM identity_org.core_organization)) \g /dev/null
INSERT INTO identity_org.evt_outbox (event_type, aggregate_type, aggregate_id, organization_id, payload_json)
SELECT 'OrganizationUpdated', 'core.organization', o.organization_id, o.organization_id,
       jsonb_build_object('organizationId', o.organization_id, 'orgCode', o.org_code, 'orgName', o.org_name,
                          'legalName', o.legal_name, 'panNo', o.pan_no, 'cinNo', o.cin_no, 'logoUri', o.logo_uri,
                          'isActive', o.is_active, 'rowVer', o.row_ver)
  FROM identity_org.core_organization o WHERE o.organization_id = :org_id
RETURNING outbox_id;
COMMIT;
SQL
  )
  [[ "$outbox_id" =~ ^[0-9]+$ ]] || die "could not create organization $ORG_ID in $DB_NAME"
  echo "[$DB_NAME] organization $ORG_ID $ORG_CODE '$ORG_NAME' saved; OrganizationUpdated queued (identity_org.evt_outbox $outbox_id)"

  if [ "$PUBLISH" = 0 ]; then echo "--no-publish: identity-org's outbox relay will publish it"; return; fi

  # Topology, as EventConsumer / OutboxRelay declare it (declaring again with the same arguments is a no-op).
  local vhost exchange="hims.$TENANT.events" dlx="hims.events.dlx" queue
  vhost=$(printf '%s' "$MQ_VHOST" | sed 's|%|%25|g; s|/|%2F|g')
  mq PUT "/exchanges/$vhost/$exchange" '{"type":"topic","durable":true}' >/dev/null
  mq PUT "/exchanges/$vhost/$dlx" '{"type":"direct","durable":true}' >/dev/null
  for svc in $SERVICES; do
    queue="$svc.$TENANT.events"
    mq PUT "/queues/$vhost/$queue.dlq" '{"durable":true,"auto_delete":false}' >/dev/null
    mq POST "/bindings/$vhost/e/$dlx/q/$queue.dlq" "{\"routing_key\":\"$queue\"}" >/dev/null
    mq PUT "/queues/$vhost/$queue" "{\"durable\":true,\"auto_delete\":false,\"arguments\":{\"x-dead-letter-exchange\":\"$dlx\",\"x-dead-letter-routing-key\":\"$queue\"}}" >/dev/null
    mq POST "/bindings/$vhost/e/$exchange/q/$queue" '{"routing_key":"OrganizationUpdated"}' >/dev/null
    echo "[rabbitmq] $queue bound to $exchange (OrganizationUpdated)"
  done

  # The EventEnvelope OutboxRelay would build from this outbox row, wrapped in a management-API publish request.
  local body response
  body=$(psql -d "$DB_NAME" -v ON_ERROR_STOP=1 -Atq -v outbox_id="$outbox_id" <<'SQL' | tr -d '\r'
SELECT jsonb_build_object(
         'routing_key', event_type,
         'payload_encoding', 'string',
         'properties', jsonb_build_object('delivery_mode', 2, 'content_type', 'application/json', 'message_id', event_id::text,
                                          'type', event_type, 'app_id', 'identity-org'),
         'payload', jsonb_build_object(
             'specVersion', '1.0', 'id', event_id::text, 'type', event_type, 'source', 'identity-org',
             'subject', aggregate_type || '/' || aggregate_id,
             'time', to_char(occurred_at AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'),
             'data', payload_json, 'organizationId', organization_id, 'branchId', branch_id, 'patientId', patient_id,
             'correlationId', correlation_id, 'aggregateType', aggregate_type, 'aggregateId', aggregate_id,
             'eventVersion', event_version, 'sourceVersion', outbox_id)::text)::text
  FROM identity_org.evt_outbox WHERE outbox_id = :outbox_id;
SQL
  )
  response=$(mq POST "/exchanges/$vhost/$exchange/publish" "$body")
  case "$response" in
    *'"routed":true'*) ;;
    *) die "publish to $exchange was not routed ($response); the outbox row stays unpublished for identity-org's relay" ;;
  esac
  echo "UPDATE identity_org.evt_outbox SET published_at = CURRENT_TIMESTAMP, last_error = NULL WHERE outbox_id = :outbox_id AND published_at IS NULL;" \
    | psql -d "$DB_NAME" -v ON_ERROR_STOP=1 -q -v outbox_id="$outbox_id"
  echo "[rabbitmq] OrganizationUpdated published to $exchange"
  echo "Add the tenant to each service's configuration (ConnectionStrings:$TENANT -> $DB_NAME, Tenants: { \"Name\": \"$TENANT\", \"OrganizationId\": $ORG_ID }) and restart them; they then replicate it into <service>.ref_organization."
}

case "$COMMAND" in
  database) create_database ;;
  tenant)   create_tenant ;;
  all)      create_database; create_tenant ;;
esac
echo "done."

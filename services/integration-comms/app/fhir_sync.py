"""
Integration Hub subscriber: consumes each tenant's exchange (hims.reddys.events, hims.apollo.events), keeps this service's ref.* copies current and mirrors clinical data to the
FHIR server (HAPI), recording every relational-row <-> FHIR-resource link in intg.fhir_resource_map. Each event is handled in its
organization's database and synced to its organization's FHIR server (reddys -> hims_reddys + /reddys/fhir, apollo -> ...).

Idempotent consumer, like the .NET services: evt.inbox insert + ref upsert + FHIR push + inbox update happen in ONE database
transaction. A duplicate event is skipped; a failure (FHIR server down, patient not yet synced) rolls everything back and the
consumer retries, then dead-letters to integration-comms.events.dlq.
"""
import json
import logging
from typing import Callable, Optional

from . import db
from . import fhir_map as fm
from .config import Tenant, settings
from .fhir_client import FhirClient, FhirError

log = logging.getLogger("hub.fhirsync")

# README subscribes the hub to PatientRegistered, PatientUpdated, EncounterClosed, LabReportReleased, PrescriptionIssued.
# EncounterStarted and OrderPlaced are added here so encounters and lab orders exist in FHIR before their results (extension).
SUBSCRIBED = ["PatientRegistered", "PatientUpdated", "EncounterStarted", "EncounterClosed", "OrderPlaced", "PrescriptionIssued", "LabReportReleased"]

REF_PATIENT = (db.table("ref", "patient"), "patient_id", ["uhid", "abha_number", "title", "first_name", "middle_name", "last_name", "date_of_birth", "gender",
                                             "blood_group", "mobile", "is_vip", "is_confidential", "is_deceased", "merged_into_patient_id"])
REF_ENCOUNTER = (db.table("ref", "encounter"), "encounter_id", ["organization_id", "branch_id", "encounter_no", "patient_id", "encounter_type", "department_id",
                                                   "specialty_id", "attending_practitioner_id", "tariff_plan_id", "primary_patient_payer_id",
                                                   "financial_class", "is_mlc", "start_at", "end_at", "encounter_status"])


class NotReady(RuntimeError):
    """A resource this one refers to has not been synced yet (events can arrive out of order); the consumer retries."""


def camel(column: str) -> str:
    head, *tail = column.split("_")
    return head + "".join(t.capitalize() for t in tail)


def upsert_ref(conn, spec: tuple, data: dict, version: Optional[int]) -> None:
    """ref.* read-model upsert; an older event never overwrites a newer row (source_version check)."""
    table, key, cols = spec
    names = [key] + cols + ["source_version"]
    values = [data.get(camel(key))] + [data.get(camel(c)) for c in cols] + [version]
    if values[0] is None:
        raise ValueError(f"payload has no {camel(key)} for {table}")
    sets = ", ".join(f"{c} = EXCLUDED.{c}" for c in cols + ["source_version"])
    conn.execute(
        f"INSERT INTO {table} ({', '.join(names)}) VALUES ({', '.join(['%s'] * len(names))}) "
        f"ON CONFLICT ({key}) DO UPDATE SET {sets}, replicated_at = now() "
        f"WHERE {table}.source_version IS NULL OR {table}.source_version < EXCLUDED.source_version", values)


class Ctx:
    """One event being processed: database transaction + FHIR client + helpers."""

    def __init__(self, conn, fhir: Optional[FhirClient], env: dict):
        self.conn, self.fhir, self.env = conn, fhir, env

    def lookup(self, entity_type: str, entity_id, rtype: str) -> Optional[str]:
        if entity_id is None:
            return None
        row = self.conn.execute(f"SELECT fhir_resource_id FROM {db.table('intg', 'fhir_resource_map')} WHERE entity_type = %s AND entity_id = %s AND fhir_resource_type = %s",
                                (entity_type, entity_id, rtype)).fetchone()
        return row["fhir_resource_id"] if row else None

    def require(self, entity_type: str, entity_id, rtype: str) -> Optional[str]:
        if self.fhir is None:
            return None
        found = self.lookup(entity_type, entity_id, rtype)
        if found is None:
            raise NotReady(f"{rtype} for {entity_type} {entity_id} is not in FHIR yet")
        return found

    def push(self, entity_type: str, entity_id, rtype: str, resource: dict) -> Optional[str]:
        if self.fhir is None:
            return None
        corr = self.env.get("id")
        try:
            res = self.fhir.conditional_put(rtype, fm.system_for(entity_type), str(entity_id), resource)
        except Exception as e:
            with db.pool().connection() as other:            # separate connection: this transaction is about to roll back
                db.log_message(other, interface_code="FHIR", direction="OUT", message_type=rtype, correlation_id=corr, entity_type=entity_type,
                               entity_id=int(entity_id), status="FAILED", error=str(e))
            raise
        self.conn.execute(
            f"""INSERT INTO {db.table('intg', 'fhir_resource_map')} (entity_type, entity_id, fhir_resource_type, fhir_resource_id, fhir_version_id, last_synced_at, sync_status)
               VALUES (%s, %s, %s, %s, %s, now(), 'SYNCED')
               ON CONFLICT (entity_type, entity_id, fhir_resource_type)
               DO UPDATE SET fhir_resource_id = EXCLUDED.fhir_resource_id, fhir_version_id = EXCLUDED.fhir_version_id, last_synced_at = now(), sync_status = 'SYNCED'""",
            (entity_type, entity_id, rtype, res["id"], res.get("versionId")))
        db.log_message(self.conn, interface_code="FHIR", direction="OUT", message_type=rtype, correlation_id=corr, entity_type=entity_type,
                       entity_id=int(entity_id), status="PROCESSED")
        return res["id"]


# ------------------------------------------------------------------------------------------------ handlers

def on_patient(ctx: Ctx, d: dict) -> None:
    upsert_ref(ctx.conn, REF_PATIENT, d, ctx.env.get("sourceVersion"))
    ctx.push("pat.patient", d["patientId"], "Patient", fm.patient_resource(d))


def on_encounter(ctx: Ctx, d: dict) -> None:
    upsert_ref(ctx.conn, REF_ENCOUNTER, d, ctx.env.get("sourceVersion"))
    pid = ctx.require("pat.patient", d["patientId"], "Patient")
    ctx.push("pat.encounter", d["encounterId"], "Encounter", fm.encounter_resource(d, pid))


def _patient_and_encounter(ctx: Ctx, d: dict) -> tuple:
    pid = ctx.require("pat.patient", d["patientId"], "Patient")
    eid = ctx.require("pat.encounter", d["encounterId"], "Encounter") if d.get("encounterId") else None
    return pid, eid


def on_order_placed(ctx: Ctx, d: dict) -> None:
    pid, eid = _patient_and_encounter(ctx, d)
    for item in d.get("items", []):
        ctx.push("ord.order_item", item["orderItemId"], "ServiceRequest", fm.service_request_resource(d, item, pid, eid))


def on_prescription(ctx: Ctx, d: dict) -> None:
    pid, eid = _patient_and_encounter(ctx, d)
    for item in d.get("items", []):
        ctx.push("ord.prescription_item", item["prescriptionItemId"], "MedicationRequest", fm.medication_request_resource(d, item, pid, eid))


def on_lab_report(ctx: Ctx, d: dict) -> None:
    pid, eid = _patient_and_encounter(ctx, d)
    observation_ids = []
    for r in d.get("results", []):
        based_on = ctx.lookup("ord.order_item", r.get("orderItemId"), "ServiceRequest")
        oid = ctx.push("lab.result", r["resultId"], "Observation", fm.observation_resource(d, r, pid, eid, based_on))
        if oid:
            observation_ids.append(oid)
    ctx.push("lab.report", d["labReportId"], "DiagnosticReport", fm.diagnostic_report_resource(d, observation_ids, pid, eid))


HANDLERS: dict = {
    "PatientRegistered": on_patient, "PatientUpdated": on_patient,
    "EncounterStarted": on_encounter, "EncounterClosed": on_encounter,
    "OrderPlaced": on_order_placed, "PrescriptionIssued": on_prescription, "LabReportReleased": on_lab_report,
}

_clients: dict = {}   # FHIR base URL -> FhirClient


def tenants() -> dict:
    """organization_id -> Tenant (REDDYS_ORGANIZATION_ID / REDDYS_DATABASE_URL / REDDYS_FHIR_URL, APOLLO_..., in .env)."""
    return {t.organization_id: t for t in db.tenants()}


def tenant_for(env: dict) -> Tenant:
    """The tenant of the event, found from its organizationId (Reddy's -> reddys, Apollo -> apollo)."""
    org = env.get("organizationId")
    tenant = db.tenant_for_organization(org)
    if tenant is None:
        raise FhirError(f"No tenant configured for organization {org} (set <SUBDOMAIN>_ORGANIZATION_ID and <SUBDOMAIN>_DATABASE_URL)")
    return tenant


def client_for(tenant: Tenant) -> Optional[FhirClient]:
    """The tenant's FHIR server; HAPI_FHIR_URL when the tenant has none."""
    if not settings.fhir_sync_enabled:
        return None
    url = tenant.fhir_url or settings.hapi_fhir_url
    if not url:
        raise FhirError(f"No FHIR server configured for {tenant.subdomain} (set {tenant.subdomain.upper()}_FHIR_URL)")
    if url not in _clients:
        _clients[url] = FhirClient(url)
    return _clients[url]


def handle_event(body: bytes, routing_key: str, fhir: Optional[FhirClient] = None, queue_tenant: Optional[Tenant] = None) -> None:
    """queue_tenant: the tenant whose exchange the event came from; the event's organizationId must agree with it."""
    env = json.loads(body)
    etype = env.get("type") or routing_key
    fn: Optional[Callable] = HANDLERS.get(etype)
    if fn is None:
        return
    tenant = tenant_for(env)
    if queue_tenant is not None and tenant.subdomain != queue_tenant.subdomain:
        raise FhirError(f"{etype} {env.get('id')} is for {tenant.subdomain} but came from {settings.exchange_for(queue_tenant.subdomain)}")
    client = fhir if fhir is not None else client_for(tenant)
    with db.using(tenant), db.tx() as conn:
        first_time = conn.execute(
            f"INSERT INTO {db.table('evt', 'inbox')} (message_id, event_type, source_service) VALUES (%s, %s, %s) ON CONFLICT (message_id) DO NOTHING RETURNING message_id",
            (env["id"], etype, env.get("source", "unknown"))).fetchone()
        if not first_time:
            log.info("Duplicate %s %s ignored (already in evt.inbox)", etype, env["id"])
            return
        fn(Ctx(conn, client, env), env["data"])
        conn.execute(f"UPDATE {db.table('evt', 'inbox')} SET process_status = 'PROCESSED', processed_at = now() WHERE message_id = %s", (env["id"],))
    log.info("Handled %s %s (%s)", etype, env["id"], tenant.subdomain)

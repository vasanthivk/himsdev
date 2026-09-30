# Integration Hub (Python)

The only non-.NET backend. Run locally:

    cd services/integration
    pip install -r requirements.txt
    export DATABASE_URL=postgresql://hims:hims@localhost:5432/hims_integration   # see .env.example
    uvicorn app.main:app --port 5011

Swagger UI: http://localhost:5011/docs

| Module | Role |
|---|---|
| `parsers.py` | HL7 v2 ORU, HL7 v3 XML and FHIR Bundle/Observation -> normalised analytes (+ HL7 ACK) |
| `inbound.py` | parse -> `intg.message_log` + `evt.outbox` (`AnalyzerResultReceived`) in one transaction |
| `bus.py` | RabbitMQ: outbox relay, resilient consumers with retry + dead-letter queues |
| `fhir_map.py`, `fhir_sync.py`, `fhir_client.py` | domain events -> FHIR R4 resources in HAPI, tracked in `intg.fhir_resource_map` |
| `engine.py` | clones the template channel in the Open Integration Engine per device |
| `simulator.py` | builds device messages so the loop works without hardware |

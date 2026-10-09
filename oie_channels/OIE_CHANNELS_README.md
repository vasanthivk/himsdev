# Open Integration Engine Channels

**HIMS &middot; Laboratory device integration**

This folder holds the channel definitions that connect laboratory analyzers to HIMS through the Open Integration Engine.
A *channel* is one configured route inside the engine: it listens for messages from a device, and forwards each message
to HIMS.

---

## At a glance

| | |
|---|---|
| **Channels in this folder** | 5 |
| **Used by the HIMS lab workflow** | 2 &mdash; `HIMS-HL7V2-Inbound` and `HIMS-Lab-Results` |
| **Reference / proof-of-concept** | 3 |
| **Device standards covered** | HL7 v2 (over TCP/MLLP) and FHIR / JSON (over HTTP) |
| **Engine version** | Open Integration Engine 4.5.2 |

---

## How a result reaches HIMS

```
  ┌────────────┐      ┌──────────────────────────┐      ┌────────────┐      ┌─────────────────┐      ┌────────────┐
  │  Analyzer  │ ───▶ │  Open Integration Engine │ ───▶ │  RabbitMQ  │ ───▶ │ Integration Hub │ ───▶ │ Laboratory │
  │  (device)  │      │         channel          │      │  (queue)   │      │  (parse, map)   │      │   (LIMS)   │
  └────────────┘      └──────────────────────────┘      └────────────┘      └─────────────────┘      └─────┬──────┘
   HL7 v2 or FHIR       receives, acknowledges,          lab.results          reads the message,           │ on report release
                        forwards the message                                  identifies the device        ▼
                                                                                                     ┌────────────┐
                                                                                                     │ FHIR server│
                                                                                                     └────────────┘
```

1. The analyzer sends its result to the engine channel that matches its standard.
2. The channel acknowledges the device and forwards the unchanged message to RabbitMQ.
3. The Integration Hub reads the message, identifies the analyzer and passes the result to Laboratory.
4. When the lab report is verified and released, the result is also stored on the FHIR server.

---

## Channels used by HIMS

### 1. `HIMS-HL7V2-Inbound`

For analyzers that send **HL7 v2** messages, which covers most laboratory instruments.

| | |
|---|---|
| **File** | `HIMS-HL7V2-Inbound.xml` |
| **Receives** | HL7 v2.x over TCP using MLLP |
| **Listens on** | Port `6661` |
| **Forwards to** | RabbitMQ, routing key `lab.results` |

### 2. `HIMS-Lab-Results`

For devices and middleware that send **FHIR or JSON** over HTTP.

| | |
|---|---|
| **File** | `HIMS-Lab-Results.xml` |
| **Receives** | JSON / FHIR over HTTP |
| **Listens on** | Port `6665`, path `/hims-lab` |
| **Forwards to** | RabbitMQ, routing key `lab.results` |

---

## Reference channels

These were built to prove individual capabilities of the engine. They are deployed, but the HIMS lab workflow does not depend on them.

| Channel | File | Receives | Listens on | Forwards to |
|---|---|---|---|---|
| `NEW-ORU-Inbound` | `NEW-ORU-Inbound.xml` | HL7 v2.x over TCP | Port `6662` | File on the engine server |
| `Linux FHIR Channel` | `Linux FHIR Channel.xml` | FHIR / JSON over HTTP | Port `6664`, path `/fhir` | File on the engine server |
| `Linux FHIR--RABITMQ Channel` | `Linux FHIR--RABITMQ Channel.xml` | FHIR / JSON over HTTP | Port `6663`, path `/fhir` | RabbitMQ, routing key `fhir.observation.queue` |

---

## Choosing a channel for a device

| The device sends | Use channel | Address the device is configured with |
|---|---|---|
| HL7 v2 over TCP/MLLP | `HIMS-HL7V2-Inbound` | `<engine host>:<published port for 6661>` |
| FHIR / JSON over HTTP | `HIMS-Lab-Results` | `http://<engine host>:<published port for 6665>/hims-lab` |

> **Ports.** The ports listed in this document are the ones inside the engine. Devices outside the engine server reach them
> through the published (mapped) port for that server.

One channel serves every device of its standard. HIMS tells devices apart by the identifier each one sends in its message
(the sending application, HL7 field `MSH-3`), which is recorded when the device is registered under **Laboratory > Analyzers**.

---

## About the files

Each `.xml` file is an export of one channel, taken from the engine administrator. The files are a **backup and reference copy**:

* The running channels live in the engine's own database. Changing a file here does not change the engine.
* HIMS does not read these files at run time.

| Task | Steps in the engine administrator |
|---|---|
| **Update the backup** after changing a channel | **Channels** &rarr; select the channel &rarr; **Export Channel** &rarr; save over the file in this folder |
| **Restore** a channel, or copy it to another engine | **Channels** &rarr; **Import Channel** &rarr; choose the file &rarr; **Deploy Channel** |

---

## Configuration notes

For engineers maintaining the channels:

* **Data types for HL7 v2.** In **Set Data Types**, the source outbound type and the destination types must be `HL7 v2.x`.
  A destination left on `JSON` cannot read an HL7 v2 message and reports a transformer error.
* **Segment separators.** HL7 v2 segments are separated by carriage returns. The destination script must keep them when it
  places the message in the RabbitMQ request (`JSON.stringify(raw).slice(1, -1)`), otherwise HIMS cannot parse the result.
* **Shared channels.** These channels have fixed ports and routing keys. Creating one channel per device needs a template
  with placeholders, described in `docs/ENGINE_TEMPLATE.md`.

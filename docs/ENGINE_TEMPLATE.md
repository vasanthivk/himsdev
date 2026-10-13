# Open Integration Engine: channels created from "Add a device"

On Laboratory > Analyzers > **Add a device**, ticking **Create a channel for this device in the Open Integration Engine** makes
Laboratory call the Integration Hub (`POST /api/interfaces`). The hub does **not** hand-write channel XML: it takes a channel
template, fills its placeholders, and creates and deploys the result as `HIMS-<analyzer code>`. Adding the same device again, or
pressing **Provision**, updates that channel and redeploys it.

Not ticked, the device is only saved (`channel_status = NOT_CREATED`) and uses a channel that already exists in the engine.

## One template per protocol

The templates are files in `services/integration/app/channel_templates/`, made from the working channels exported to `oie_channels/`.

| Protocol | Template | Made from | Source connector | Data type |
|---|---|---|---|---|
| HL7 v2 | `hl7v2.xml` | `HIMS-HL7V2-Inbound.xml` | TCP Listener (MLLP) on `${LISTEN_PORT}` | HL7 v2.x |
| HL7 v3 | `hl7v3.xml` | `HIMS-HL7V3-Inbound.xml` | HTTP Listener on `${LISTEN_PORT}`, path `${CONTEXT_PATH}` | HL7 v3.x |
| FHIR | `fhir.xml` | `HIMS-Lab-Results.xml` | HTTP Listener on `${LISTEN_PORT}`, path `${CONTEXT_PATH}` | JSON |

Every template has one destination, an HTTP Sender that publishes the unchanged device message to RabbitMQ through its management
API: exchange `hims.integration`, routing key `lab.results.<analyzer code>`. The hub's device consumer reads it from the
`lab.results` queue (bound with `lab.results.#`).

Other protocols (ASTM, LIS2-A2, FILE) have no template; their channel has to be made in the engine by hand.

## What the hub needs

| Value | Where it comes from |
|---|---|
| Engine URL, user, password, verify TLS | The Add-device form, saved on `lab.analyzer`. Empty = the hub's `ENGINE_*` setting. |
| Listen port | The form's **Listen port**, used as entered. Empty = the hub's `ENGINE_FIRST_LISTEN_PORT` (default 6661) + analyzer id. |
| RabbitMQ management API address | `RABBITMQ_API_URL` of the hub (`services/integration/.env`): the address **as the engine reaches it**. |
| RabbitMQ user, password, virtual host | Taken from the hub's `RABBITMQ_URL`. |

Before creating the channel the hub checks that no other channel in the engine already listens on the port, and reports
`FAILED` with the name of that channel if one does.

The listen port is the port **inside** the engine. A device (or the simulator) outside the engine server can reach the channel only if
that port is published on the server; put the published address in the form's **Engine channel URL**
(`mllp://host:port` for HL7 v2, `http://host:port/<path>` for HL7 v3 and FHIR).

## Placeholders

| Placeholder | Filled with |
|---|---|
| `${CHANNEL_ID}` `${CHANNEL_NAME}` | A new id (or the existing channel's id) and `HIMS-<analyzer code>` |
| `${ANALYZER_ID}` `${ANALYZER_CODE}` `${ANALYZER_NAME}` `${PROTOCOL}` `${SENDING_APPLICATION_ID}` | The device as entered on the form |
| `${LISTEN_PORT}` | The listen port |
| `${CONTEXT_PATH}` | `/<analyzer code in lower case>` (HTTP templates) |
| `${ROUTING_KEY}` | `lab.results.<analyzer code in lower case>` |
| `${RABBITMQ_PUBLISH_URL}` `${RABBITMQ_USER}` `${RABBITMQ_PASSWORD}` | `<RABBITMQ_API_URL>/api/exchanges/<vhost>/hims.integration/publish` and the RabbitMQ login |
| `${RABBITMQ_URI}` `${RABBITMQ_EXCHANGE}` `${HUB_INBOUND_URL}` | Not used by the three templates; available if one is changed: the AMQP URL, `hims.integration`, and `<HUB_PUBLIC_URL of the hub>/api/inbound?analyzer=<code>` |

`${payloadEscaped}` in the templates is the engine's own variable (set by the destination's transformer script), not a hub placeholder.

## Changing a template

To change a template: change the channel in the engine, export it to `oie_channels/`, and put the placeholders above back
in place of the port, context path, RabbitMQ URL, login and routing key.

## Status

The REST calls follow the Mirth-compatible API (`/api/users/_login`, `/api/channels/idsAndNames`, `/api/channels`,
`/api/channels/{id}/_deploy`). After each attempt the filled-in channel is written to `services/integration/data/last_rendered_channel_<code>.xml`
for inspection.

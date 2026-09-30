# Open Integration Engine: the template channel

"Add device" in Laboratory calls the Integration Hub (`POST /api/interfaces`). The hub does **not** hand-write channel XML: it clones a
template channel you create once, fills placeholders, and deploys the clone as `HIMS-<analyzer code>`.
Set `ENGINE_URL`, `ENGINE_USER`, `ENGINE_PASSWORD` for the hub (see `services/integration/.env.example`). Without `ENGINE_URL` the analyzer is saved
with `channel_status = PENDING` and nothing is created in the engine.

## Create the template once
In the engine's administrator, create a channel named exactly **`HIMS-Analyzer-Template`** (the name is `ENGINE_TEMPLATE_CHANNEL`):

* **Source: TCP Listener** (MLLP), port `${LISTEN_PORT}`, data type HL7 v2.x. (For HL7 v3 or FHIR devices use an HTTP/TCP listener with the
  matching data type instead; keep the same placeholders.)
* **Destination: JavaScript Writer** that publishes the raw message to RabbitMQ. Add the RabbitMQ Java client jar to the engine's custom lib first.

```javascript
// Destination script. ${...} values are replaced by the hub when it clones this channel.
var factory = new Packages.com.rabbitmq.client.ConnectionFactory();
factory.setUri('${RABBITMQ_URI}');
var connection = factory.newConnection();
var channel = connection.createChannel();
try {
  channel.exchangeDeclare('${RABBITMQ_EXCHANGE}', 'topic', true);
  var body = new java.lang.String(connectorMessage.getEncodedData()).getBytes('UTF-8');
  channel.basicPublish('${RABBITMQ_EXCHANGE}', '${ROUTING_KEY}', null, body);
} finally { channel.close(); connection.close(); }
return ACK;
```
* (Optional) HTTP Sender destination to `${HUB_INBOUND_URL}` instead of RabbitMQ; the hub answers with an HL7 ACK.

## Placeholders the hub fills
`${ANALYZER_ID} ${ANALYZER_CODE} ${ANALYZER_NAME} ${PROTOCOL} ${SENDING_APPLICATION_ID} ${DEVICE_HOST} ${LISTEN_PORT} ${ROUTING_KEY} ${RABBITMQ_URI} ${RABBITMQ_EXCHANGE} ${HUB_INBOUND_URL}`

`${LISTEN_PORT}` is the port entered when adding the device, else `ENGINE_FIRST_LISTEN_PORT + analyzer id`.
The clone gets a new channel id and the name `HIMS-<code>`; re-provisioning an existing device updates that channel and redeploys it.

Not tested against a live engine (none was available while writing this); the REST calls follow the Mirth-compatible API
(`/api/users/_login`, `/api/channels/idsAndNames`, `/api/channels`, `/api/channels/{id}/_deploy`).

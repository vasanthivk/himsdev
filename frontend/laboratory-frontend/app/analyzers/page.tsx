'use client';
import { useEffect, useState } from 'react';
import { API, api, errMsg } from '@/lib/api';
import { Alert, Badge, Card, Field, statusTone } from '@/components/ui';

const blank = { branchId: '', analyzerCode: '', analyzerName: '', manufacturer: '', model: '', labSection: 'HEMATOLOGY', interfaceProtocol: 'HL7V2',
  sendingApplicationId: '', isBidirectional: false,
  createChannel: false,   // ticked = a channel for this device is created in the Open Integration Engine when it is added
  // Open Integration Engine connection for this device; a field left empty uses the Integration Hub's own setting
  engineUrl: '', engineUser: '', enginePassword: '', engineVerifyTls: false, engineFirstListenPort: '',
  engineChannelUrl: '' };

// Protocols the Integration Hub has a channel template for; other protocols need a channel made by hand in the engine
const TEMPLATED = ['HL7V2', 'HL7V3', 'FHIR'];

export default function Analyzers() {
  const [msg, setMsg] = useState<{ kind: 'ok' | 'error' | 'warn'; text: string } | null>(null);
  const [branches, setBranches] = useState<any[]>([]);
  const [list, setList] = useState<any[]>([]);
  const [tests, setTests] = useState<any[]>([]);
  const [form, setForm] = useState<any>(blank);
  const [map, setMap] = useState({ analyzerId: '', labParameterId: '', machineTestCode: '' });
  const [maps, setMaps] = useState<any[]>([]);

  const bad = (e: unknown) => setMsg({ kind: 'error', text: errMsg(e) });
  const load = () => api(API.laboratory, '/api/analyzers').then(setList).catch(bad);
  const set = (k: string) => (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => setForm({ ...form, [k]: e.target.value });

  useEffect(() => {
    api(API.laboratory, '/api/branches').then((b) => { setBranches(b); if (b[0]) setForm((f: any) => ({ ...f, branchId: String(b[0].branchId) })); }).catch(bad);
    api(API.laboratory, '/api/tests').then(setTests).catch(bad);
    load();
  }, []);

  useEffect(() => {
    if (map.analyzerId) api(API.laboratory, `/api/analyzers/${map.analyzerId}/parameter-map`).then(setMaps).catch(bad); else setMaps([]);
  }, [map.analyzerId]);

  async function add(e: React.FormEvent) {
    e.preventDefault(); setMsg(null);
    const body: any = { ...form, branchId: Number(form.branchId),
      engineFirstListenPort: form.engineFirstListenPort ? Number(form.engineFirstListenPort) : null };
    body.createChannel = creating;
    Object.keys(body).forEach((k) => { if (body[k] === '') delete body[k]; });
    try {
      const r = await api(API.laboratory, '/api/analyzers', { body });
      const done = r.analyzer.channelStatus === 'PROVISIONED' || !creating;
      setMsg({ kind: done ? 'ok' : 'warn', text: creating ? `${r.analyzer.analyzerCode} added. Channel ${r.analyzer.channelStatus}: ${r.provisioningMessage}` : `${r.analyzer.analyzerCode} added. ${r.provisioningMessage}` });
      setForm({ ...blank, branchId: form.branchId }); load();
    } catch (err) { bad(err); }
  }

  async function reprovision(id: number) {
    try { const r = await api(API.laboratory, `/api/analyzers/${id}/provision`, { method: 'POST' }); setMsg({ kind: r.analyzer.channelStatus === 'PROVISIONED' ? 'ok' : 'warn', text: `Channel ${r.analyzer.channelStatus}: ${r.provisioningMessage}` }); load(); } catch (e) { bad(e); }
  }

  async function addMap(e: React.FormEvent) {
    e.preventDefault();
    try {
      await api(API.laboratory, `/api/analyzers/${map.analyzerId}/parameter-map`, { body: { labParameterId: Number(map.labParameterId), machineTestCode: map.machineTestCode } });
      setMap({ ...map, machineTestCode: '' });
      setMaps(await api(API.laboratory, `/api/analyzers/${map.analyzerId}/parameter-map`));
    } catch (err) { bad(err); }
  }

  const creating = form.createChannel && TEMPLATED.includes(form.interfaceProtocol);
  const isHttp = form.interfaceProtocol !== 'HL7V2';
  const params = tests.flatMap((t) => t.parameters.map((p: any) => ({ ...p, testName: t.serviceName })));

  return (
    <>
      <h1>Analyzers (devices)</h1>
      {msg && <Alert kind={msg.kind}>{msg.text}</Alert>}

      <Card title="Add a device">
        <form onSubmit={add}>
          <div className="grid">
            <Field label="Branch"><select value={form.branchId} onChange={set('branchId')}>{branches.map((b) => <option key={b.branchId} value={b.branchId}>{b.branchName}</option>)}</select></Field>
            <Field label="Analyzer code *"><input required maxLength={20} value={form.analyzerCode} onChange={set('analyzerCode')} placeholder="SYSMEX-XN" /></Field>
            <Field label="Name *"><input required value={form.analyzerName} onChange={set('analyzerName')} placeholder="Sysmex XN-1000 Haematology" /></Field>
            <Field label="Manufacturer"><input value={form.manufacturer} onChange={set('manufacturer')} /></Field>
            <Field label="Model"><input value={form.model} onChange={set('model')} /></Field>
            <Field label="Lab section"><select value={form.labSection} onChange={set('labSection')}><option>HEMATOLOGY</option><option>BIOCHEMISTRY</option><option>IMMUNOLOGY</option><option>MICROBIOLOGY</option></select></Field>
            <Field label="Protocol"><select value={form.interfaceProtocol} onChange={set('interfaceProtocol')}><option value="HL7V2">HL7 v2</option><option value="HL7V3">HL7 v3</option><option value="FHIR">FHIR</option><option value="ASTM">ASTM</option></select></Field>
            <Field label="Sending application id"><input value={form.sendingApplicationId} onChange={set('sendingApplicationId')} placeholder="what the device sends in MSH-3 (default: code)" /></Field>
            <label className="row" style={{ alignSelf: 'end' }}><input type="checkbox" style={{ width: 'auto' }} checked={form.isBidirectional} onChange={(e) => setForm({ ...form, isBidirectional: e.target.checked })} />bidirectional</label>
          </div>
          <h3 style={{ marginTop: 16 }}>Open Integration Engine</h3>
          <label className="row"><input type="checkbox" style={{ width: 'auto' }} checked={form.createChannel} disabled={!TEMPLATED.includes(form.interfaceProtocol)} onChange={(e) => setForm({ ...form, createChannel: e.target.checked })} />Create a channel for this device in the Open Integration Engine</label>
          {!TEMPLATED.includes(form.interfaceProtocol)
            ? <p className="muted">There is no channel template for {form.interfaceProtocol}. Create its channel in the engine yourself; the device is only saved here.</p>
            : creating
              ? <p className="muted">When the device is added, the channel <strong>HIMS-{form.analyzerCode || '<analyzer code>'}</strong> is created from the {form.interfaceProtocol} template and deployed: {isHttp ? `an HTTP listener on the listen port, path /${(form.analyzerCode || 'analyzer-code').toLowerCase().replace(/[^a-z0-9]+/g, '-')}` : 'a TCP/MLLP listener on the listen port'}. That port must be free in the engine and published on its server.</p>
              : <p className="muted">Not ticked: no channel is created. Enter the details of the engine and of the channel this device already uses; they are saved with the device.</p>}
          <div className="grid">
            <Field label={creating ? 'Engine URL *' : 'Engine URL'}><input required={creating} value={form.engineUrl} onChange={set('engineUrl')} placeholder="https://engine-host:8443" /></Field>
            <Field label={creating ? 'Engine user *' : 'Engine user'}><input required={creating} value={form.engineUser} onChange={set('engineUser')} placeholder="admin" autoComplete="off" /></Field>
            <Field label={creating ? 'Engine password *' : 'Engine password'}><input required={creating} type="password" value={form.enginePassword} onChange={set('enginePassword')} autoComplete="new-password" /></Field>
            <Field label="Listen port"><input type="number" value={form.engineFirstListenPort} onChange={set('engineFirstListenPort')} placeholder={creating ? 'port inside the engine, e.g. 6663 (auto if empty)' : "the channel's port inside the engine"} /></Field>
            <Field label="Engine channel URL"><input value={form.engineChannelUrl} onChange={set('engineChannelUrl')} placeholder="http://engine-host:port/path or mllp://engine-host:port" /></Field>
            <label className="row" style={{ alignSelf: 'end' }}><input type="checkbox" style={{ width: 'auto' }} checked={form.engineVerifyTls} onChange={(e) => setForm({ ...form, engineVerifyTls: e.target.checked })} />verify engine TLS certificate</label>
          </div>
          <p className="muted">Engine channel URL: the address, as reached from outside the engine server, that test messages for this device are sent to.</p>
          <div style={{ marginTop: 12 }}><button>{creating ? 'Add device & create integration channel' : 'Add device'}</button></div>
        </form>
      </Card>

      <Card title="Registered devices" actions={<button className="secondary" onClick={load}>Refresh</button>}>
        <table><thead><tr><th>Code</th><th>Name</th><th>Protocol</th><th>Device id (MSH-3)</th><th>Channel</th><th>Routing key</th><th /></tr></thead><tbody>
          {list.map((a) => (
            <tr key={a.analyzerId}><td><strong>{a.analyzerCode}</strong></td><td>{a.analyzerName}<div className="muted">{a.manufacturer} {a.model}</div></td><td>{a.interfaceProtocol}</td><td>{a.sendingApplicationId}</td>
              <td><Badge tone={statusTone(a.channelStatus)}>{a.channelStatus ?? '-'}</Badge><div className="muted">{a.integrationChannelId}</div><div className="muted">{a.engineUrl}</div></td><td className="muted">{a.routingKey}</td>
              <td>{a.channelStatus !== 'PROVISIONED' && <button className="secondary" onClick={() => reprovision(a.analyzerId)}>Provision</button>}</td></tr>))}
          {list.length === 0 && <tr><td colSpan={7} className="muted">No devices yet.</td></tr>}
        </tbody></table>
      </Card>

      <Card title="Map the device's test codes to lab parameters">
        <p className="muted">Optional. Without a mapping the hub's parameter code (LOINC) is matched directly to the lab parameter.</p>
        <form className="grid" onSubmit={addMap}>
          <Field label="Device"><select required value={map.analyzerId} onChange={(e) => setMap({ ...map, analyzerId: e.target.value })}><option value="">Select</option>{list.map((a) => <option key={a.analyzerId} value={a.analyzerId}>{a.analyzerCode}</option>)}</select></Field>
          <Field label="Lab parameter"><select required value={map.labParameterId} onChange={(e) => setMap({ ...map, labParameterId: e.target.value })}><option value="">Select</option>{params.map((p) => <option key={p.labParameterId} value={p.labParameterId}>{p.testName} - {p.parameterName}</option>)}</select></Field>
          <Field label="Machine test code"><input required value={map.machineTestCode} onChange={(e) => setMap({ ...map, machineTestCode: e.target.value })} placeholder="WBC" /></Field>
          <div style={{ alignSelf: 'end' }}><button>Save mapping</button></div>
        </form>
        {maps.length > 0 && <table><thead><tr><th>Machine code</th><th>Parameter</th><th>Factor</th></tr></thead><tbody>
          {maps.map((m) => <tr key={m.analyzerParameterMapId}><td>{m.machineTestCode}</td><td>{params.find((p) => p.labParameterId === m.labParameterId)?.parameterName ?? m.labParameterId}</td><td>{m.conversionFactor ?? '-'}</td></tr>)}</tbody></table>}
      </Card>
    </>
  );
}

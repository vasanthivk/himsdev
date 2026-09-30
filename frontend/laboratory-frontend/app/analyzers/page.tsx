'use client';
import { useEffect, useState } from 'react';
import { API, api, errMsg } from '@/lib/api';
import { Alert, Badge, Card, Field, statusTone } from '@/components/ui';

const blank = { branchId: '', analyzerCode: '', analyzerName: '', manufacturer: '', model: '', labSection: 'HEMATOLOGY', interfaceProtocol: 'HL7V2',
  sendingApplicationId: '', hostAddress: '', port: '', isBidirectional: false };

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
    const body: any = { ...form, branchId: Number(form.branchId), port: form.port ? Number(form.port) : null };
    Object.keys(body).forEach((k) => { if (body[k] === '') delete body[k]; });
    try {
      const r = await api(API.laboratory, '/api/analyzers', { body });
      setMsg({ kind: r.analyzer.channelStatus === 'PROVISIONED' ? 'ok' : 'warn', text: `${r.analyzer.analyzerCode} added. Channel ${r.analyzer.channelStatus}: ${r.provisioningMessage}` });
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
            <Field label="Host"><input value={form.hostAddress} onChange={set('hostAddress')} placeholder="192.168.1.50" /></Field>
            <Field label="Port"><input type="number" value={form.port} onChange={set('port')} placeholder="auto" /></Field>
            <label className="row" style={{ alignSelf: 'end' }}><input type="checkbox" style={{ width: 'auto' }} checked={form.isBidirectional} onChange={(e) => setForm({ ...form, isBidirectional: e.target.checked })} />bidirectional</label>
          </div>
          <div style={{ marginTop: 12 }}><button>Add device &amp; create integration channel</button></div>
        </form>
      </Card>

      <Card title="Registered devices" actions={<button className="secondary" onClick={load}>Refresh</button>}>
        <table><thead><tr><th>Code</th><th>Name</th><th>Protocol</th><th>Device id (MSH-3)</th><th>Channel</th><th>Routing key</th><th /></tr></thead><tbody>
          {list.map((a) => (
            <tr key={a.analyzerId}><td><strong>{a.analyzerCode}</strong></td><td>{a.analyzerName}<div className="muted">{a.manufacturer} {a.model}</div></td><td>{a.interfaceProtocol}</td><td>{a.sendingApplicationId}</td>
              <td><Badge tone={statusTone(a.channelStatus)}>{a.channelStatus ?? '-'}</Badge><div className="muted">{a.integrationChannelId}</div></td><td className="muted">{a.routingKey}</td>
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

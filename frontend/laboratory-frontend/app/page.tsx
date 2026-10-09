'use client';
import Link from 'next/link';
import { useCallback, useEffect, useState } from 'react';
import { API, api, errMsg } from '@/lib/api';
import { Alert, Badge, Card, statusTone, when } from '@/components/ui';

type Pay = { isPaid?: boolean; billNo?: string; billStatus?: string; notBilled?: boolean };

export default function Lab() {
  const [msg, setMsg] = useState<{ kind: 'ok' | 'error' | 'info'; text: string } | null>(null);
  const [pending, setPending] = useState<any[]>([]);
  const [pay, setPay] = useState<Record<number, Pay>>({});
  const [samples, setSamples] = useState<any[]>([]);
  const [results, setResults] = useState<Record<number, any[]>>({});
  const [analyzers, setAnalyzers] = useState<any[]>([]);
  const [sim, setSim] = useState({ analyzerCode: 'SIMULATOR', format: 'HL7V2', via: 'rabbitmq', abnormal: false, critical: false });
  const [override, setOverride] = useState(false);
  const [busy, setBusy] = useState('');

  const bad = (e: unknown) => setMsg({ kind: 'error', text: errMsg(e) });

  const load = useCallback(async () => {
    try {
      const p: any[] = await api(API.laboratory, '/api/worklist/pending');
      setPending(p);
      // Billing status comes from Revenue Cycle: a sample is only collected once its bill is paid.
      const ids = p.flatMap((o) => o.items.map((i: any) => i.orderItemId as number));
      const entries = await Promise.all(ids.map(async (id) => {
        try { const b = await api(API.revenueCycle, `/api/bills/by-order-item/${id}`); return [id, b] as const; }
        catch { return [id, { notBilled: true }] as const; }
      }));
      setPay(Object.fromEntries(entries));
      const s: any[] = await api(API.laboratory, '/api/samples');
      setSamples(s);
      const res = await Promise.all(s.map((x) => api(API.laboratory, `/api/results?sampleId=${x.sampleId}`).then((r) => [x.sampleId, r] as const).catch(() => [x.sampleId, []] as const)));
      setResults(Object.fromEntries(res));
      setAnalyzers(await api(API.laboratory, '/api/analyzers'));
    } catch (e) { bad(e); }
  }, []);

  useEffect(() => { load(); const t = setInterval(load, 5000); return () => clearInterval(t); }, [load]);

  const orderPaid = (o: any) => o.items.every((i: any) => pay[i.orderItemId]?.isPaid);

  async function collect(o: any) {
    setBusy(`c${o.orderId}`); setMsg(null);
    try {
      const made: any[] = await api(API.laboratory, '/api/samples', { body: { orderId: o.orderId, orderItemIds: o.items.map((i: any) => i.orderItemId), collectionLocation: 'CENTRE' } });
      setMsg({ kind: 'ok', text: `Collected ${made.length} sample(s): ${made.map((m) => m.sampleBarcode).join(', ')}` }); load();
    } catch (e) { bad(e); }
    setBusy('');
  }

  async function simulate(s: any) {
    setBusy(`s${s.sampleId}`); setMsg(null);
    try {
      // "via engine" posts to the selected device's own channel endpoint (entered when the device was added)
      const engineChannelUrl = analyzers.find((a) => a.analyzerCode === sim.analyzerCode)?.engineChannelUrl || undefined;
      const r = await api(API.integration, '/api/simulator/send', { body: { sampleBarcode: s.sampleBarcode, serviceCodes: s.serviceCodes, ...sim, engineChannelUrl } });
      setMsg({ kind: 'info', text: `Device message ${r.messageId} sent via ${r.delivered}. It flows Integration Hub -> RabbitMQ -> Laboratory; results appear below in a few seconds.` });
    } catch (e) { bad(e); }
    setBusy('');
  }

  async function verify(s: any) {
    try { await api(API.laboratory, `/api/samples/${s.sampleId}/verify`, { method: 'POST' }); setMsg({ kind: 'ok', text: 'Verified.' }); load(); } catch (e) { bad(e); }
  }

  return (
    <>
      <h1>Laboratory</h1>
      {msg && <Alert kind={msg.kind}>{msg.text}</Alert>}

      <Card title="1. Pending orders" actions={<div className="row"><label className="row" style={{ gap: 4 }}><input type="checkbox" style={{ width: 'auto' }} checked={override} onChange={(e) => setOverride(e.target.checked)} />collect even if unpaid</label><button className="secondary" onClick={load}>Refresh</button></div>}>
        {pending.length === 0 && <p className="muted">Nothing waiting. Orders appear here when the doctor orders lab tests (OrderPlaced event).</p>}
        {pending.map((o) => (
          <div key={o.orderId} style={{ marginBottom: 14 }}>
            <div className="row" style={{ justifyContent: 'space-between' }}>
              <div><strong>{o.orderNo}</strong> &middot; {o.patientName} <span className="muted">({o.uhid})</span></div>
              <button disabled={busy === `c${o.orderId}` || (!override && !orderPaid(o))} onClick={() => collect(o)}>Collect sample{o.items.length > 1 ? 's' : ''}</button>
            </div>
            <table><tbody>
              {o.items.map((i: any) => {
                const p = pay[i.orderItemId];
                return (
                  <tr key={i.orderItemId}><td>{i.serviceName}</td><td className="muted">{i.specimenType} / {i.containerType}</td>
                    <td>{!p ? <Badge>checking</Badge> : p.notBilled ? <Badge tone="amber">awaiting bill</Badge> : p.isPaid ? <Badge tone="green">paid {p.billNo}</Badge> : <Badge tone="red">unpaid {p.billNo}</Badge>}</td></tr>
                );
              })}
            </tbody></table>
          </div>
        ))}
      </Card>

      <Card title="2. Samples and results" actions={
        <div className="row">
          <span className="muted">Simulated device:</span>
          <select value={sim.analyzerCode} onChange={(e) => setSim({ ...sim, analyzerCode: e.target.value })}>
            <option value="SIMULATOR">SIMULATOR (unregistered)</option>{analyzers.map((a) => <option key={a.analyzerId} value={a.analyzerCode}>{a.analyzerCode}</option>)}</select>
          <select value={sim.format} onChange={(e) => setSim({ ...sim, format: e.target.value })}><option value="HL7V2">HL7 v2</option><option value="HL7V3">HL7 v3</option><option value="FHIR">FHIR</option></select>
          <select value={sim.via} onChange={(e) => setSim({ ...sim, via: e.target.value })}>
            <option value="rabbitmq">via RabbitMQ (skip engine)</option>
            <option value="engine">via Open Integration Engine</option>
          </select>
          <label className="row" style={{ gap: 4 }}><input type="checkbox" style={{ width: 'auto' }} checked={sim.abnormal} onChange={(e) => setSim({ ...sim, abnormal: e.target.checked, critical: false })} />abnormal</label>
          <label className="row" style={{ gap: 4 }}><input type="checkbox" style={{ width: 'auto' }} checked={sim.critical} onChange={(e) => setSim({ ...sim, critical: e.target.checked, abnormal: false })} />critical</label>
        </div>}>
        <table><thead><tr><th>Barcode</th><th>Patient</th><th>Tests</th><th>Status</th><th>Results</th><th /></tr></thead><tbody>
          {samples.map((s) => (
            <tr key={s.sampleId}><td><strong>{s.sampleBarcode}</strong><div className="muted">{s.specimenType} / {s.containerType} &middot; {when(s.collectedAt)}</div></td>
              <td>{s.patientName ?? s.patientId}</td><td>{s.serviceCodes.join(', ')}</td>
              <td><Badge tone={statusTone(s.sampleStatus)}>{s.sampleStatus}</Badge></td>
              <td>{(results[s.sampleId] ?? []).map((r) => (
                <div key={r.resultId} className={r.isCritical ? 'crit' : ''}>{r.parameterName}: <strong>{r.valueNumeric ?? r.valueText}</strong> {r.unit} {r.abnormalFlag && r.abnormalFlag !== 'N' ? <Badge tone={r.isCritical ? 'red' : 'amber'}>{r.abnormalFlag}</Badge> : null} <Badge tone={statusTone(r.resultStatus)}>{r.resultStatus}</Badge></div>))}</td>
              <td className="row">
                <button disabled={busy === `s${s.sampleId}`} onClick={() => simulate(s)}>Send device result</button>
                {(results[s.sampleId] ?? []).some((r) => r.resultStatus === 'ENTERED') && <button className="secondary" onClick={() => verify(s)}>Verify</button>}
              </td></tr>))}
          {samples.length === 0 && <tr><td colSpan={6} className="muted">No samples yet.</td></tr>}
        </tbody></table>
        <p className="muted">A real analyzer sends the message on its own. Register it under <Link href="/analyzers">Analyzers</Link>; the button above plays the device.</p>
      </Card>
    </>
  );
}

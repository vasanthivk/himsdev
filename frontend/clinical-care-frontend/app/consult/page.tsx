'use client';
import { Suspense, useCallback, useEffect, useState } from 'react';
import { useSearchParams } from 'next/navigation';
import { API, api, errMsg } from '@/lib/api';
import { Alert, Badge, Card, Field, fullName, statusTone, when } from '@/components/ui';

const blankRx = () => ({ drugText: '', dose: '', doseUnit: 'mg', route: 'ORAL', frequency: 'BD', timing: 'AFTER_FOOD', durationValue: '5', durationUnit: 'days', instructions: '' });

function Consult() {
  const encounterId = Number(useSearchParams().get('encounterId'));
  const [ctx, setCtx] = useState<any>(null);
  const [msg, setMsg] = useState<{ kind: 'ok' | 'error'; text: string } | null>(null);

  // consultation note
  const [note, setNote] = useState({ chiefComplaint: '', subjective: '', objective: '', assessment: '', plan: '' });
  const [dx, setDx] = useState<{ text: string; type: string; isPrimary: boolean }[]>([{ text: '', type: 'PROVISIONAL', isPrimary: true }]);
  // lab order
  const [tests, setTests] = useState<any[]>([]);
  const [picked, setPicked] = useState<number[]>([]);
  const [priority, setPriority] = useState('ROUTINE');
  const [indication, setIndication] = useState('');
  // prescription
  const [rx, setRx] = useState<any[]>([blankRx()]);
  const [advice, setAdvice] = useState('');
  const [followup, setFollowup] = useState('');
  // history
  const [orders, setOrders] = useState<any[]>([]);
  const [results, setResults] = useState<any[]>([]);
  const [rxList, setRxList] = useState<any[]>([]);

  const practitionerId = ctx?.encounter?.attendingPractitionerId ?? undefined;
  const patientId = ctx?.patient?.patientId;
  const ok = (text: string) => setMsg({ kind: 'ok', text });
  const bad = (e: unknown) => setMsg({ kind: 'error', text: errMsg(e) });

  const refresh = useCallback(async () => {
    if (!encounterId || !patientId) return;
    try {
      setOrders(await api(API.clinicalCare, `/api/orders?encounterId=${encounterId}`));
      setRxList(await api(API.clinicalCare, `/api/prescriptions?encounterId=${encounterId}`));
      setResults(await api(API.laboratory, `/api/results?patientId=${patientId}`));   // lab results come straight from the Laboratory service
    } catch { /* transient */ }
  }, [encounterId, patientId]);

  useEffect(() => {
    if (!encounterId) return;
    api(API.clinicalCare, `/api/encounters/${encounterId}`).then(setCtx).catch(bad);
    api(API.clinicalCare, '/api/catalog/services?type=LAB_TEST').then(setTests).catch(bad);
  }, [encounterId]);

  useEffect(() => { refresh(); const t = setInterval(refresh, 5000); return () => clearInterval(t); }, [refresh]);

  async function saveNote(e: React.FormEvent) {
    e.preventDefault(); setMsg(null);
    try {
      await api(API.clinicalCare, '/api/consultations', { retry409: true, body: {
        encounterId, authorPractitionerId: practitionerId, ...note,
        diagnoses: dx.filter((d) => d.text.trim()).map((d) => ({ text: d.text, type: d.type, isPrimary: d.isPrimary })),
      } });
      ok('Consultation note signed and saved.');
    } catch (err) { bad(err); }
  }

  async function placeOrder() {
    setMsg(null);
    try {
      await api(API.clinicalCare, '/api/orders', { retry409: true, body: {
        encounterId, orderingPractitionerId: practitionerId, priority, clinicalIndication: indication || null,
        items: picked.map((serviceId) => ({ serviceId, quantity: 1 })),
      } });
      setPicked([]); ok('Lab order placed. Revenue Cycle raises the bill from the OrderPlaced event; the lab sees it on its worklist.'); refresh();
    } catch (err) { bad(err); }
  }

  async function issueRx(e: React.FormEvent) {
    e.preventDefault(); setMsg(null);
    try {
      await api(API.clinicalCare, '/api/prescriptions', { retry409: true, body: {
        encounterId, practitionerId, advice: advice || null, followupDate: followup || null,
        items: rx.filter((r) => r.drugText.trim()).map((r) => ({
          drugText: r.drugText, dose: r.dose ? Number(r.dose) : null, doseUnit: r.doseUnit || null, route: r.route || null, frequency: r.frequency,
          timing: r.timing || null, durationValue: r.durationValue ? Number(r.durationValue) : null, durationUnit: r.durationUnit || null, instructions: r.instructions || null,
        })),
      } });
      setRx([blankRx()]); setAdvice(''); setFollowup(''); ok('Prescription issued.'); refresh();
    } catch (err) { bad(err); }
  }

  async function closeVisit() {
    if (!confirm('Close this visit?')) return;
    try { await api(API.patientAccess, `/api/encounters/${encounterId}/close`, { method: 'POST' }); ok('Visit closed.'); } catch (err) { bad(err); }
  }

  const updRx = (i: number, k: string, v: string) => setRx(rx.map((r, j) => (j === i ? { ...r, [k]: v } : r)));
  const resultsFor = (itemId: number) => results.filter((r) => r.orderItemId === itemId);

  if (!encounterId) return <Alert kind="warn">No visit selected. Pick one from the <a href="/clinical-care">doctor queue</a>.</Alert>;
  return (
    <>
      <h1>Consultation</h1>
      {msg && <Alert kind={msg.kind}>{msg.text}</Alert>}
      {ctx && (
        <Card actions={<button className="danger" onClick={closeVisit}>Close visit</button>}>
          <div className="row" style={{ gap: 28 }}>
            <div><div className="muted">Patient</div><strong>{fullName(ctx.patient)}</strong> &middot; {ctx.patient?.uhid}</div>
            <div><div className="muted">Gender / DOB</div>{ctx.patient?.gender} / {ctx.patient?.dateOfBirth ?? '-'}</div>
            <div><div className="muted">Visit</div>{ctx.encounter.encounterNo} <Badge tone={statusTone(ctx.encounter.encounterStatus)}>{ctx.encounter.encounterStatus}</Badge></div>
            <div><div className="muted">Doctor</div>{ctx.practitioner?.displayName ?? '-'}</div>
          </div>
        </Card>
      )}

      <Card title="Consultation note (SOAP) and diagnoses">
        <form onSubmit={saveNote}>
          <div className="grid">
            <Field label="Chief complaint *" wide><input required value={note.chiefComplaint} onChange={(e) => setNote({ ...note, chiefComplaint: e.target.value })} /></Field>
            <Field label="Subjective (history)" wide><textarea value={note.subjective} onChange={(e) => setNote({ ...note, subjective: e.target.value })} /></Field>
            <Field label="Objective (examination)" wide><textarea value={note.objective} onChange={(e) => setNote({ ...note, objective: e.target.value })} /></Field>
            <Field label="Assessment" wide><textarea value={note.assessment} onChange={(e) => setNote({ ...note, assessment: e.target.value })} /></Field>
            <Field label="Plan" wide><textarea value={note.plan} onChange={(e) => setNote({ ...note, plan: e.target.value })} /></Field>
          </div>
          <h2 style={{ fontSize: 14, margin: '14px 0 6px' }}>Diagnoses</h2>
          {dx.map((d, i) => (
            <div className="row" key={i} style={{ marginBottom: 6 }}>
              <input style={{ flex: 1 }} placeholder="Diagnosis" value={d.text} onChange={(e) => setDx(dx.map((x, j) => (j === i ? { ...x, text: e.target.value } : x)))} />
              <select style={{ width: 150 }} value={d.type} onChange={(e) => setDx(dx.map((x, j) => (j === i ? { ...x, type: e.target.value } : x)))}>{['PROVISIONAL', 'DIFFERENTIAL', 'FINAL'].map((t) => <option key={t}>{t}</option>)}</select>
              <label className="row" style={{ gap: 4 }}><input type="checkbox" style={{ width: 'auto' }} checked={d.isPrimary} onChange={(e) => setDx(dx.map((x, j) => (j === i ? { ...x, isPrimary: e.target.checked } : x)))} />primary</label>
              <button type="button" className="secondary" onClick={() => setDx(dx.filter((_, j) => j !== i))}>Remove</button>
            </div>
          ))}
          <div className="row" style={{ marginTop: 8 }}>
            <button type="button" className="secondary" onClick={() => setDx([...dx, { text: '', type: 'PROVISIONAL', isPrimary: false }])}>+ Add diagnosis</button>
            <button>Sign &amp; save note</button>
          </div>
        </form>
      </Card>

      <div className="split">
        <Card title="Order lab tests">
          <div className="checks">
            {tests.map((t) => (
              <label key={t.serviceId}><input type="checkbox" checked={picked.includes(t.serviceId)}
                onChange={(e) => setPicked(e.target.checked ? [...picked, t.serviceId] : picked.filter((x) => x !== t.serviceId))} />{t.serviceName}</label>
            ))}
            {tests.length === 0 && <span className="muted">No orderable tests yet - load reference data on the home page.</span>}
          </div>
          <div className="grid" style={{ marginTop: 10 }}>
            <Field label="Priority"><select value={priority} onChange={(e) => setPriority(e.target.value)}><option>ROUTINE</option><option>URGENT</option><option>STAT</option></select></Field>
            <Field label="Clinical indication"><input value={indication} onChange={(e) => setIndication(e.target.value)} /></Field>
          </div>
          <div style={{ marginTop: 10 }}><button disabled={picked.length === 0} onClick={placeOrder}>Place order ({picked.length})</button></div>
        </Card>

        <Card title="Prescription">
          <form onSubmit={issueRx}>
            {rx.map((r, i) => (
              <div key={i} style={{ borderBottom: '1px solid var(--line)', paddingBottom: 8, marginBottom: 8 }}>
                <div className="grid">
                  <Field label="Drug *" wide><input value={r.drugText} onChange={(e) => updRx(i, 'drugText', e.target.value)} placeholder="e.g. Paracetamol 500 mg tablet" /></Field>
                  <Field label="Dose"><input type="number" step="any" value={r.dose} onChange={(e) => updRx(i, 'dose', e.target.value)} /></Field>
                  <Field label="Unit"><input value={r.doseUnit} onChange={(e) => updRx(i, 'doseUnit', e.target.value)} /></Field>
                  <Field label="Route"><select value={r.route} onChange={(e) => updRx(i, 'route', e.target.value)}>{['ORAL', 'IV', 'IM', 'TOPICAL', 'INHALATION'].map((x) => <option key={x}>{x}</option>)}</select></Field>
                  <Field label="Frequency"><select value={r.frequency} onChange={(e) => updRx(i, 'frequency', e.target.value)}>{['OD', 'BD', 'TDS', 'QID', 'HS', 'SOS'].map((x) => <option key={x}>{x}</option>)}</select></Field>
                  <Field label="Timing"><select value={r.timing} onChange={(e) => updRx(i, 'timing', e.target.value)}>{['AFTER_FOOD', 'BEFORE_FOOD', 'WITH_FOOD', 'BEDTIME'].map((x) => <option key={x}>{x}</option>)}</select></Field>
                  <Field label="Duration"><input type="number" value={r.durationValue} onChange={(e) => updRx(i, 'durationValue', e.target.value)} /></Field>
                  <Field label="Duration unit"><select value={r.durationUnit} onChange={(e) => updRx(i, 'durationUnit', e.target.value)}><option>days</option><option>weeks</option><option>months</option></select></Field>
                </div>
                {rx.length > 1 && <button type="button" className="danger" style={{ marginTop: 6 }} onClick={() => setRx(rx.filter((_, j) => j !== i))}>Remove drug</button>}
              </div>
            ))}
            <div className="grid">
              <Field label="Advice" wide><textarea value={advice} onChange={(e) => setAdvice(e.target.value)} /></Field>
              <Field label="Follow-up date"><input type="date" value={followup} onChange={(e) => setFollowup(e.target.value)} /></Field>
            </div>
            <div className="row" style={{ marginTop: 10 }}>
              <button type="button" className="secondary" onClick={() => setRx([...rx, blankRx()])}>+ Add drug</button>
              <button>Issue prescription</button>
            </div>
          </form>
        </Card>
      </div>

      <Card title="Orders and lab results" actions={<button className="secondary" onClick={refresh}>Refresh</button>}>
        {orders.length === 0 && <p className="muted">No orders for this visit yet.</p>}
        {orders.map((o) => (
          <div key={o.orderId} style={{ marginBottom: 12 }}>
            <div><strong>{o.orderNo}</strong> <span className="muted">{o.orderCategory} &middot; {when(o.orderedAt)}</span> <Badge tone={statusTone(o.orderStatus)}>{o.orderStatus}</Badge></div>
            <table><thead><tr><th>Test</th><th>Status</th><th>Billed</th><th>Result</th></tr></thead><tbody>
              {o.items.map((i: any) => (
                <tr key={i.orderItemId}><td>{i.serviceName}</td><td><Badge tone={statusTone(i.itemStatus)}>{i.itemStatus}</Badge></td>
                  <td>{i.isBilled ? <Badge tone="green">billed</Badge> : <Badge tone="grey">awaiting bill</Badge>}</td>
                  <td>{resultsFor(i.orderItemId).map((r) => (
                    <div key={r.resultId} className={r.isCritical ? 'crit' : ''}>
                      {r.parameterName}: <strong>{r.valueNumeric ?? r.valueText}</strong> {r.unit} {r.abnormalFlag && r.abnormalFlag !== 'N' ? <Badge tone={r.isCritical ? 'red' : 'amber'}>{r.abnormalFlag}</Badge> : null}
                      <span className="muted"> ref {r.referenceRangeText ?? '-'}</span>
                    </div>
                  ))}</td></tr>
              ))}
            </tbody></table>
          </div>
        ))}
      </Card>

      {rxList.length > 0 && (
        <Card title="Prescriptions issued">
          {rxList.map((p) => (
            <div key={p.prescriptionId} style={{ marginBottom: 8 }}>
              <strong>{p.prescriptionNo}</strong> <span className="muted">{when(p.prescribedAt)}</span>
              <ul style={{ margin: '4px 0' }}>{p.items.map((i: any) => <li key={i.prescriptionItemId}>{i.drugText} - {i.dose ?? ''} {i.doseUnit ?? ''} {i.frequency} {i.timing ?? ''} {i.durationValue ? `x ${i.durationValue} ${i.durationUnit}` : ''}</li>)}</ul>
            </div>
          ))}
        </Card>
      )}
    </>
  );
}

export default function Page() { return <Suspense fallback={null}><Consult /></Suspense>; }

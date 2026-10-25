'use client';
import { Suspense, useCallback, useEffect, useState } from 'react';
import { useSearchParams } from 'next/navigation';
import { API, api, errMsg } from '@/lib/api';
import { Alert, Badge, Card, Field, fullName, money, statusTone, when } from '@/components/ui';

function Billing() {
  const params = useSearchParams();
  const [msg, setMsg] = useState<{ kind: 'ok' | 'error'; text: string } | null>(null);
  const [branches, setBranches] = useState<any[]>([]);
  const [catalog, setCatalog] = useState<any[]>([]);
  const [q, setQ] = useState('');
  const [found, setFound] = useState<any[]>([]);
  const [patient, setPatient] = useState<any>(null);
  const [encounters, setEncounters] = useState<any[]>([]);
  const [form, setForm] = useState({ branchId: '', encounterId: '', billType: 'OPD' });
  const [qty, setQty] = useState<Record<number, number>>({});
  const [bills, setBills] = useState<any[]>([]);
  const [filter, setFilter] = useState({ status: '', patientId: '' });
  const [detail, setDetail] = useState<any>(null);
  const [pay, setPay] = useState<{ billId: number; amount: string; mode: string; ref: string } | null>(null);

  const ok = (text: string) => setMsg({ kind: 'ok', text });
  const bad = (e: unknown) => setMsg({ kind: 'error', text: errMsg(e) });

  const loadBills = useCallback(async (f = filter) => {
    const qs = [f.status && `status=${f.status}`, f.patientId && `patientId=${f.patientId}`].filter(Boolean).join('&');
    try { setBills(await api(API.revenueFinance, `/api/bills${qs ? `?${qs}` : ''}`)); } catch (e) { bad(e); }
  }, [filter]);

  const selectPatient = useCallback(async (p: any, preferEncounter?: string) => {
    setPatient(p); setFound([]);
    setFilter((f) => ({ ...f, patientId: String(p.patientId) }));
    try {
      const enc = await api(API.revenueFinance, `/api/encounters?patientId=${p.patientId}`);
      setEncounters(enc);
      setForm((f) => ({ ...f, encounterId: preferEncounter ?? (enc[0] ? String(enc[0].encounterId) : '') }));
    } catch (e) { bad(e); }
    loadBills({ status: '', patientId: String(p.patientId) });
  }, [loadBills]);

  useEffect(() => {
    api(API.revenueFinance, '/api/branches').then((b) => { setBranches(b); if (b[0]) setForm((f) => ({ ...f, branchId: String(b[0].branchId) })); }).catch(bad);
    api(API.revenueFinance, '/api/services').then(setCatalog).catch(bad);
    const pid = params.get('patientId');
    if (pid) api(API.revenueFinance, `/api/patients/${pid}`).then((p) => selectPatient(p, params.get('encounterId') ?? undefined)).catch(bad);
    else loadBills({ status: '', patientId: '' });
    const t = setInterval(() => loadBills(), 6000);      // lab bills appear here a moment after the doctor places an order
    return () => clearInterval(t);
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  async function search(e: React.FormEvent) {
    e.preventDefault();
    try { setFound(await api(API.revenueFinance, `/api/patients?q=${encodeURIComponent(q)}`)); } catch (err) { bad(err); }
  }

  const chosen = Object.entries(qty).filter(([, n]) => n > 0).map(([id, n]) => ({ serviceId: Number(id), quantity: n }));
  const estimate = chosen.reduce((s, c) => s + (catalog.find((x) => x.serviceId === c.serviceId)?.rate ?? 0) * c.quantity, 0);

  async function createBill() {
    if (!patient) return;
    setMsg(null);
    try {
      const b = await api(API.revenueFinance, '/api/bills', { retry409: true, body: {
        patientId: patient.patientId, encounterId: form.encounterId ? Number(form.encounterId) : null, branchId: Number(form.branchId), billType: form.billType, lines: chosen } });
      setQty({}); ok(`Bill ${b.billNo} raised for ${money(b.netAmount)}.`); loadBills();
    } catch (e) { bad(e); }
  }

  async function takePayment() {
    if (!pay) return;
    try {
      const r = await api(API.revenueFinance, `/api/bills/${pay.billId}/pay`, { body: { amount: pay.amount ? Number(pay.amount) : null, paymentMode: pay.mode, referenceNo: pay.ref || null } });
      ok(`Receipt ${r.receiptNo}: ${money(r.amount)} received. Bill ${r.billNo} is ${r.billStatus}.`); setPay(null); setDetail(null); loadBills();
    } catch (e) { bad(e); }
  }

  async function view(id: number) { try { setDetail(await api(API.revenueFinance, `/api/bills/${id}`)); } catch (e) { bad(e); } }

  return (
    <>
      <h1>Billing</h1>
      {msg && <Alert kind={msg.kind}>{msg.text}</Alert>}

      <div className="split">
        <Card title="1. Patient">
          <form className="row" onSubmit={search}>
            <input style={{ flex: 1 }} placeholder="UHID, mobile or name" value={q} onChange={(e) => setQ(e.target.value)} /><button>Search</button>
          </form>
          {found.length > 0 && <table><tbody>{found.map((p) => (
            <tr key={p.patientId}><td>{p.uhid}</td><td>{fullName(p)}</td><td>{p.mobile}</td><td><button className="secondary" onClick={() => selectPatient(p)}>Select</button></td></tr>))}</tbody></table>}
          {patient && <p><strong>{fullName(patient)}</strong> <span className="muted">&middot; {patient.uhid} &middot; {patient.mobile}</span></p>}
          {patient && (
            <div className="grid">
              <Field label="Visit"><select value={form.encounterId} onChange={(e) => setForm({ ...form, encounterId: e.target.value })}><option value="">(none)</option>
                {encounters.map((e) => <option key={e.encounterId} value={e.encounterId}>{e.encounterNo} - {e.encounterStatus}</option>)}</select></Field>
              <Field label="Branch"><select value={form.branchId} onChange={(e) => setForm({ ...form, branchId: e.target.value })}>{branches.map((b) => <option key={b.branchId} value={b.branchId}>{b.branchName}</option>)}</select></Field>
            </div>
          )}
        </Card>

        <Card title="2. Services (registration, consultation ...)">
          <table><tbody>
            {catalog.filter((s) => s.serviceType !== 'LAB_TEST').map((s) => (
              <tr key={s.serviceId}><td>{s.serviceName}</td><td className="num">{money(s.rate)}</td>
                <td style={{ width: 70 }}><input type="number" min={0} value={qty[s.serviceId] ?? 0} onChange={(e) => setQty({ ...qty, [s.serviceId]: Number(e.target.value) })} /></td></tr>))}
          </tbody></table>
          <p className="muted">Lab tests are billed automatically when the doctor orders them (see the bills below).</p>
          <div className="row"><strong>Estimate {money(estimate)}</strong><button disabled={!patient || chosen.length === 0} onClick={createBill}>Raise bill</button></div>
        </Card>
      </div>

      <Card title="Bills" actions={
        <div className="row">
          <select value={filter.status} onChange={(e) => { const f = { ...filter, status: e.target.value }; setFilter(f); loadBills(f); }}>
            <option value="">All statuses</option><option>FINALISED</option><option>PARTIALLY_PAID</option><option>SETTLED</option></select>
          {filter.patientId && <button className="secondary" onClick={() => { const f = { status: filter.status, patientId: '' }; setFilter(f); loadBills(f); }}>All patients</button>}
          <button className="secondary" onClick={() => loadBills()}>Refresh</button>
        </div>}>
        <table><thead><tr><th>Bill</th><th>Patient</th><th>Type</th><th className="num">Net</th><th className="num">Paid</th><th className="num">Due</th><th>Status</th><th /></tr></thead><tbody>
          {bills.map((b) => (
            <tr key={b.billId}><td>{b.billNo}<div className="muted">{when(b.billDate)}</div></td><td>{b.patientName ?? b.patientId}<div className="muted">{b.uhid}</div></td><td>{b.billType}</td>
              <td className="num">{money(b.netAmount)}</td><td className="num">{money(b.paidAmount)}</td><td className="num">{money(b.dueAmount)}</td>
              <td><Badge tone={statusTone(b.billStatus)}>{b.billStatus}</Badge></td>
              <td className="row"><button className="secondary" onClick={() => view(b.billId)}>View</button>
                {b.dueAmount > 0 && <button onClick={() => setPay({ billId: b.billId, amount: String(b.dueAmount), mode: 'CASH', ref: '' })}>Pay</button>}</td></tr>))}
          {bills.length === 0 && <tr><td colSpan={8} className="muted">No bills.</td></tr>}
        </tbody></table>
      </Card>

      {pay && (
        <Card title="Take payment">
          <div className="grid">
            <Field label="Amount"><input type="number" step="0.01" value={pay.amount} onChange={(e) => setPay({ ...pay, amount: e.target.value })} /></Field>
            <Field label="Mode"><select value={pay.mode} onChange={(e) => setPay({ ...pay, mode: e.target.value })}>{['CASH', 'CARD', 'UPI', 'CHEQUE', 'NEFT'].map((m) => <option key={m}>{m}</option>)}</select></Field>
            <Field label="Reference no."><input value={pay.ref} onChange={(e) => setPay({ ...pay, ref: e.target.value })} /></Field>
          </div>
          <div className="row" style={{ marginTop: 10 }}><button onClick={takePayment}>Receive payment</button><button className="secondary" onClick={() => setPay(null)}>Cancel</button></div>
        </Card>
      )}

      {detail && (
        <Card title={`Bill ${detail.bill.billNo}`} actions={<button className="secondary" onClick={() => setDetail(null)}>Close</button>}>
          <table><thead><tr><th>Service</th><th className="num">Qty</th><th className="num">Rate</th><th className="num">Amount</th></tr></thead><tbody>
            {detail.lines.map((l: any) => <tr key={l.billLineId}><td>{l.description}</td><td className="num">{l.quantity}</td><td className="num">{money(l.unitRate)}</td><td className="num">{money(l.netAmount)}</td></tr>)}
          </tbody></table>
          <p className="muted">Gross {money(detail.bill.grossAmount)} &middot; tax {money(detail.bill.cgstAmount + detail.bill.sgstAmount)} &middot; round-off {money(detail.bill.roundOff)} &middot; <strong>net {money(detail.bill.netAmount)}</strong></p>
          {detail.receipts.map((r: any) => <div key={r.receiptId}>Receipt {r.receiptNo}: {money(r.allocatedAmount)} on {when(r.receiptAt)}</div>)}
        </Card>
      )}
    </>
  );
}

export default function Page() { return <Suspense fallback={null}><Billing /></Suspense>; }

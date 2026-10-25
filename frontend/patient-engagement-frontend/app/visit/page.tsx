'use client';
import { Suspense, useEffect, useState } from 'react';
import { useSearchParams } from 'next/navigation';
import { API, api, errMsg } from '@/lib/api';
import { Alert, Badge, Card, Field, fullName, statusTone, when } from '@/components/ui';

function Visit() {
  const params = useSearchParams();
  const [q, setQ] = useState('');
  const [results, setResults] = useState<any[]>([]);
  const [patient, setPatient] = useState<any>(null);
  const [branches, setBranches] = useState<any[]>([]);
  const [doctors, setDoctors] = useState<any[]>([]);
  const [depts, setDepts] = useState<any[]>([]);
  const [encounters, setEncounters] = useState<any[]>([]);
  const [form, setForm] = useState({ branchId: '', practitionerId: '', departmentId: '', financialClass: 'SELF' });
  const [started, setStarted] = useState<any>(null);
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);

  const loadEncounters = () => api(API.patientEngagement, '/api/encounters?status=OPEN').then(setEncounters).catch(() => undefined);

  useEffect(() => {
    Promise.all([api(API.patientEngagement, '/api/branches'), api(API.patientEngagement, '/api/practitioners'), api(API.patientEngagement, '/api/departments')])
      .then(([b, d, dp]) => {
        setBranches(b); setDoctors(d); setDepts(dp);
        setForm((f) => ({ ...f, branchId: b[0] ? String(b[0].branchId) : '', practitionerId: d[0] ? String(d[0].practitionerId) : '' }));
      }).catch((e) => setError(errMsg(e)));
    loadEncounters();
    const id = params.get('patientId');
    if (id) api(API.patientEngagement, `/api/patients/${id}`).then(setPatient).catch((e) => setError(errMsg(e)));
  }, [params]);

  async function search(e: React.FormEvent) {
    e.preventDefault(); setError('');
    try { setResults(await api(API.patientEngagement, `/api/patients?q=${encodeURIComponent(q)}`)); } catch (err) { setError(errMsg(err)); }
  }

  async function start(e: React.FormEvent) {
    e.preventDefault(); setBusy(true); setError(''); setStarted(null);
    try {
      const enc = await api(API.patientEngagement, '/api/encounters', {
        body: {
          patientId: patient.patientId, branchId: Number(form.branchId), encounterType: 'OPD', financialClass: form.financialClass,
          attendingPractitionerId: form.practitionerId ? Number(form.practitionerId) : null, departmentId: form.departmentId ? Number(form.departmentId) : null,
        },
      });
      setStarted(enc); loadEncounters();
    } catch (err) { setError(errMsg(err)); }
    setBusy(false);
  }

  return (
    <>
      <h1>OP visit</h1>
      {error && <Alert kind="error">{error}</Alert>}
      <div className="split">
        <Card title="1. Find the patient">
          <form className="row" onSubmit={search}>
            <input style={{ flex: 1 }} placeholder="UHID, mobile or name" value={q} onChange={(e) => setQ(e.target.value)} />
            <button>Search</button>
          </form>
          {results.length > 0 && (
            <table><thead><tr><th>UHID</th><th>Name</th><th>Mobile</th><th /></tr></thead><tbody>
              {results.map((p) => (
                <tr key={p.patientId}><td>{p.uhid}</td><td>{fullName(p)}</td><td>{p.mobile}</td>
                  <td><button className="secondary" onClick={() => { setPatient(p); setStarted(null); }}>Select</button></td></tr>
              ))}
            </tbody></table>
          )}
        </Card>

        <Card title="2. Start the visit">
          {!patient ? <p className="muted">Select a patient first.</p> : (
            <form onSubmit={start}>
              <p><strong>{fullName(patient)}</strong> <span className="muted">&middot; {patient.uhid}</span></p>
              <div className="grid">
                <Field label="Branch"><select value={form.branchId} onChange={(e) => setForm({ ...form, branchId: e.target.value })}>{branches.map((b) => <option key={b.branchId} value={b.branchId}>{b.branchName}</option>)}</select></Field>
                <Field label="Consulting doctor"><select value={form.practitionerId} onChange={(e) => setForm({ ...form, practitionerId: e.target.value })}>{doctors.map((d) => <option key={d.practitionerId} value={d.practitionerId}>{d.displayName}</option>)}</select></Field>
                <Field label="Department"><select value={form.departmentId} onChange={(e) => setForm({ ...form, departmentId: e.target.value })}><option value="">-</option>{depts.map((d) => <option key={d.departmentId} value={d.departmentId}>{d.deptName}</option>)}</select></Field>
                <Field label="Financial class"><select value={form.financialClass} onChange={(e) => setForm({ ...form, financialClass: e.target.value })}>{['SELF', 'CORPORATE', 'INSURANCE', 'GOVT_SCHEME', 'STAFF'].map((c) => <option key={c}>{c}</option>)}</select></Field>
              </div>
              <div style={{ marginTop: 12 }}><button disabled={busy}>{busy ? 'Starting...' : 'Start OP visit'}</button></div>
            </form>
          )}
          {started && (
            <Alert kind="ok">
              Visit <strong>{started.encounterNo}</strong> started.
              <div className="row" style={{ marginTop: 8 }}>
                <a className="btn" href={`/revenue-finance?patientId=${started.patientId}&encounterId=${started.encounterId}`}>Bill registration &amp; consultation &rarr;</a>
                <a className="btn secondary" href="/clinical-care">Doctor queue</a>
              </div>
            </Alert>
          )}
        </Card>
      </div>

      <Card title="Open visits" actions={<button className="secondary" onClick={loadEncounters}>Refresh</button>}>
        <table><thead><tr><th>Visit no.</th><th>Patient id</th><th>Type</th><th>Doctor id</th><th>Started</th><th>Status</th></tr></thead><tbody>
          {encounters.map((e) => (
            <tr key={e.encounterId}><td>{e.encounterNo}</td><td>{e.patientId}</td><td>{e.encounterType}</td><td>{e.attendingPractitionerId ?? '-'}</td><td>{when(e.startAt)}</td><td><Badge tone={statusTone(e.encounterStatus)}>{e.encounterStatus}</Badge></td></tr>
          ))}
          {encounters.length === 0 && <tr><td colSpan={6} className="muted">No open visits.</td></tr>}
        </tbody></table>
      </Card>
    </>
  );
}

export default function Page() { return <Suspense fallback={null}><Visit /></Suspense>; }

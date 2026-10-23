'use client';
import Link from 'next/link';
import { useEffect, useState } from 'react';
import { API, api, errMsg } from '@/lib/api';
import { Alert, Badge, Card, statusTone, when } from '@/components/ui';

export default function Queue() {
  const [rows, setRows] = useState<any[]>([]);
  const [doctors, setDoctors] = useState<any[]>([]);
  const [doctor, setDoctor] = useState('');
  const [error, setError] = useState('');

  async function load(d = doctor) {
    try { setRows(await api(API.clinicalCare, `/api/encounters?status=OPEN${d ? `&practitionerId=${d}` : ''}`)); setError(''); } catch (e) { setError(errMsg(e)); }
  }

  useEffect(() => {
    api(API.clinicalCare, '/api/practitioners').then(setDoctors).catch(() => undefined);
    load('');
    const t = setInterval(() => load(), 8000);
    return () => clearInterval(t);
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const name = (id?: number) => doctors.find((d) => d.practitionerId === id)?.displayName ?? (id ? `#${id}` : '-');

  return (
    <>
      <h1>Doctor queue</h1>
      {error && <Alert kind="error">{error}</Alert>}
      <Card title="Open visits" actions={
        <div className="row">
          <select value={doctor} onChange={(e) => { setDoctor(e.target.value); load(e.target.value); }}>
            <option value="">All doctors</option>{doctors.map((d) => <option key={d.practitionerId} value={d.practitionerId}>{d.displayName}</option>)}
          </select>
          <button className="secondary" onClick={() => load()}>Refresh</button>
        </div>}>
        <table><thead><tr><th>Visit</th><th>Patient</th><th>UHID</th><th>Doctor</th><th>Since</th><th>Status</th><th /></tr></thead><tbody>
          {rows.map((r) => (
            <tr key={r.encounterId}><td>{r.encounterNo}</td><td>{r.patientName}</td><td>{r.uhid}</td><td>{name(r.attendingPractitionerId)}</td><td>{when(r.startAt)}</td>
              <td><Badge tone={statusTone(r.encounterStatus)}>{r.encounterStatus}</Badge></td>
              <td><Link className="btn" href={`/consult?encounterId=${r.encounterId}`}>Consult</Link></td></tr>
          ))}
          {rows.length === 0 && <tr><td colSpan={7} className="muted">No open visits. Start one from Patient Access (it appears here once the EncounterStarted event has been replicated).</td></tr>}
        </tbody></table>
      </Card>
    </>
  );
}

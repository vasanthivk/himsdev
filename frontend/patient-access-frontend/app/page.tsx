'use client';
import Link from 'next/link';
import { useEffect, useState } from 'react';
import { API, ApiError, api, errMsg } from '@/lib/api';
import { Alert, Card, Field, fullName } from '@/components/ui';

const blank = { branchId: '', title: 'Mr', firstName: '', middleName: '', lastName: '', dateOfBirth: '', gender: 'male', mobile: '', email: '',
  bloodGroup: '', addressLine1: '', city: '', stateCode: '', pincode: '' };

export default function RegisterPatient() {
  const [branches, setBranches] = useState<any[]>([]);
  const [form, setForm] = useState<any>(blank);
  const [saved, setSaved] = useState<any>(null);
  const [dup, setDup] = useState<any>(null);
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    api(API.patientAccess, '/api/branches').then((b) => {
      setBranches(b);
      if (b.length) setForm((f: any) => ({ ...f, branchId: String(b[0].branchId) }));
    }).catch((e) => setError(errMsg(e)));
  }, []);

  const set = (k: string) => (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => setForm({ ...form, [k]: e.target.value });

  async function submit(e: React.FormEvent, force = false) {
    e.preventDefault();
    setBusy(true); setError(''); setDup(null); setSaved(null);
    const body: any = { ...form, branchId: Number(form.branchId) };
    Object.keys(body).forEach((k) => { if (body[k] === '') delete body[k]; });
    try {
      const p = await api(API.patientAccess, `/api/patients${force ? '?force=true' : ''}`, { body });
      setSaved(p);
      setForm({ ...blank, branchId: form.branchId });
    } catch (err) {
      if (err instanceof ApiError && err.status === 409) setDup(err.data);
      else setError(errMsg(err));
    }
    setBusy(false);
  }

  async function useExisting() {
    try { setSaved(await api(API.patientAccess, `/api/patients/${dup.patientId}`)); setDup(null); } catch (e) { setError(errMsg(e)); }
  }

  return (
    <>
      <h1>Register patient</h1>
      {branches.length === 0 && !error && (
        <Alert kind="warn">No branches yet. Open the <a href="/">home page</a> and press <strong>Load reference data</strong>, then reload this page.</Alert>
      )}
      {error && <Alert kind="error">{error}</Alert>}

      {saved && (
        <Alert kind="ok">
          <div className="muted">Patient registered</div>
          <div className="big">{saved.uhid}</div>
          <div>{fullName(saved)} &middot; {saved.gender} &middot; {saved.mobile}</div>
          <div className="row" style={{ marginTop: 10 }}>
            <Link className="btn" href={`/visit?patientId=${saved.patientId}`}>Start OP visit &rarr;</Link>
            <a className="btn secondary" href={`/revenue-cycle?patientId=${saved.patientId}`}>Go to billing</a>
          </div>
        </Alert>
      )}

      {dup && (
        <Alert kind="warn">
          A patient with the same name, mobile and date of birth already exists (UHID <strong>{dup.uhid}</strong>).
          <div className="row" style={{ marginTop: 8 }}>
            <button onClick={useExisting}>Use existing patient</button>
            <button className="secondary" onClick={(e) => submit(e, true)}>Register as a new patient anyway</button>
          </div>
        </Alert>
      )}

      <Card title="Demographics">
        <form onSubmit={submit}>
          <div className="grid">
            <Field label="Branch *">
              <select required value={form.branchId} onChange={set('branchId')}>
                {branches.map((b) => <option key={b.branchId} value={b.branchId}>{b.branchName}</option>)}
              </select>
            </Field>
            <Field label="Title"><select value={form.title} onChange={set('title')}>{['Mr', 'Mrs', 'Ms', 'Master', 'Baby', 'Dr'].map((t) => <option key={t}>{t}</option>)}</select></Field>
            <Field label="First name *"><input required value={form.firstName} onChange={set('firstName')} /></Field>
            <Field label="Middle name"><input value={form.middleName} onChange={set('middleName')} /></Field>
            <Field label="Last name"><input value={form.lastName} onChange={set('lastName')} /></Field>
            <Field label="Date of birth"><input type="date" value={form.dateOfBirth} onChange={set('dateOfBirth')} /></Field>
            <Field label="Gender *"><select value={form.gender} onChange={set('gender')}><option>male</option><option>female</option><option>other</option><option>unknown</option></select></Field>
            <Field label="Mobile *"><input required pattern="[0-9+ ]{10,15}" title="10-15 digits" value={form.mobile} onChange={set('mobile')} /></Field>
            <Field label="Email"><input type="email" value={form.email} onChange={set('email')} /></Field>
            <Field label="Blood group"><select value={form.bloodGroup} onChange={set('bloodGroup')}><option value="">-</option>{['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'].map((g) => <option key={g}>{g}</option>)}</select></Field>
            <Field label="Address" wide><input value={form.addressLine1} onChange={set('addressLine1')} /></Field>
            <Field label="City"><input value={form.city} onChange={set('city')} /></Field>
            <Field label="State code"><input maxLength={5} value={form.stateCode} onChange={set('stateCode')} placeholder="TS" /></Field>
            <Field label="Pincode"><input value={form.pincode} onChange={set('pincode')} /></Field>
          </div>
          <div style={{ marginTop: 14 }}><button disabled={busy || branches.length === 0}>{busy ? 'Registering...' : 'Register patient'}</button></div>
        </form>
      </Card>
    </>
  );
}

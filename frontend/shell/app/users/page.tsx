'use client';
import { FormEvent, useEffect, useState } from 'react';
import { API, api, errMsg } from '@/lib/api';
import { Alert, Badge, Card, Field } from '@/components/ui';
import PasswordInput from '@/components/PasswordInput';

// Staff users (Identity & Org). Adding one creates the employee, the HIMS login and roles, notifies the other services
// (EmployeeUpdated -> their ref.employee) and creates the user in the organization's WSO2 Identity Server tenant.

type User = {
  userId: number; username: string; isActive: boolean; isLocked: boolean; lastLoginAt?: string; createdAt: string;
  employeeId?: number; employeeCode?: string; firstName?: string; lastName?: string; email?: string; mobile?: string;
  branchId?: number; departmentId?: number; roles: string[];
};
type Branch = { branchId: number; branchName: string };
type Department = { departmentId: number; deptName: string };
type Role = { roleCode: string; roleName: string };

// Role codes from the data model (sec.role); roles already defined in the database are added to the list.
const STANDARD_ROLES = ['ADMIN', 'FRONT_OFFICE', 'BILLING', 'DOCTOR', 'NURSE', 'LAB_TECH', 'PATHOLOGIST', 'RADIOLOGIST', 'PHARMACIST', 'PHLEBOTOMIST'];
const roleLabel = (code: string) => code.split('_').map((w) => w[0] + w.slice(1).toLowerCase()).join(' ');

const emptyForm = {
  branchId: '', title: 'Mr', firstName: '', lastName: '', gender: 'male', username: '', mobile: '', departmentId: '', roles: [] as string[],
  password: '', confirmPassword: '',
};

// Same rule as Identity & Org (WSO2 applies its own tenant policy as well). Empty = the configured default password.
function passwordProblem(p: string): string | null {
  if (p.length < 8 || p.length > 64) return 'Password must be 8-64 characters long.';
  if (!/[A-Z]/.test(p) || !/[a-z]/.test(p) || !/[0-9]/.test(p) || !/[^A-Za-z0-9]/.test(p)) return 'Password must contain an uppercase letter, a lowercase letter, a digit and a special character.';
  if (/\s/.test(p)) return 'Password must not contain spaces.';
  return null;
}

export default function Users() {
  const [users, setUsers] = useState<User[]>([]);
  const [branches, setBranches] = useState<Branch[]>([]);
  const [departments, setDepartments] = useState<Department[]>([]);
  const [roleCodes, setRoleCodes] = useState<string[]>(STANDARD_ROLES);
  const [form, setForm] = useState(emptyForm);
  const [msg, setMsg] = useState<{ kind: 'ok' | 'error'; text: string } | null>(null);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  async function load() {
    try {
      const [u, b, d, r] = await Promise.all([
        api<User[]>(API.identityOrg, '/api/users'),
        api<Branch[]>(API.identityOrg, '/api/branches'),
        api<Department[]>(API.identityOrg, '/api/departments'),
        api<Role[]>(API.identityOrg, '/api/roles'),
      ]);
      setUsers(u); setBranches(b); setDepartments(d);
      setRoleCodes([...new Set([...STANDARD_ROLES, ...r.map((x) => x.roleCode)])]);
      setForm((f) => (f.branchId || b.length === 0 ? f : { ...f, branchId: String(b[0].branchId) }));
      setLoadError(null);
    } catch (e) { setLoadError(errMsg(e)); }
  }
  useEffect(() => { load(); }, []);

  const set = (k: keyof typeof emptyForm) => (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => setForm({ ...form, [k]: e.target.value });
  const toggleRole = (code: string) => setForm({ ...form, roles: form.roles.includes(code) ? form.roles.filter((r) => r !== code) : [...form.roles, code] });

  async function submit(e: FormEvent) {
    e.preventDefault();
    setMsg(null);
    if (form.password || form.confirmPassword) {
      if (form.password !== form.confirmPassword) { setMsg({ kind: 'error', text: 'The passwords do not match.' }); return; }
      const problem = passwordProblem(form.password);
      if (problem) { setMsg({ kind: 'error', text: problem }); return; }
    }
    setBusy(true);
    try {
      const r = await api<any>(API.identityOrg, '/api/users', {
        body: {
          branchId: Number(form.branchId), title: form.title, firstName: form.firstName, lastName: form.lastName, gender: form.gender,
          username: form.username, mobile: form.mobile || null, departmentId: form.departmentId ? Number(form.departmentId) : null, roles: form.roles,
          password: form.password || null,
        },
      });
      setMsg({ kind: 'ok', text: `User ${r.username} created: employee ${r.employeeCode}${r.wso2 ? `, WSO2 user in ${r.wso2.tenant}` : ''}. The other services receive the employee within a few seconds.` });
      setForm({ ...emptyForm, branchId: form.branchId });
      await load();
    } catch (err) { setMsg({ kind: 'error', text: errMsg(err) }); }
    setBusy(false);
  }

  const branchName = (id?: number) => branches.find((b) => b.branchId === id)?.branchName ?? '';
  const deptName = (id?: number) => departments.find((d) => d.departmentId === id)?.deptName ?? '';

  return (
    <>
      <h1>Users</h1>
      {loadError && <Alert kind="error">{loadError}</Alert>}

      <Card title="Add user">
        <form onSubmit={submit}>
          <div className="grid">
            <Field label="Branch *">
              <select required value={form.branchId} onChange={set('branchId')}>
                {branches.map((b) => <option key={b.branchId} value={b.branchId}>{b.branchName}</option>)}
              </select>
            </Field>
            <Field label="Title"><select value={form.title} onChange={set('title')}>{['Mr', 'Mrs', 'Ms', 'Dr'].map((t) => <option key={t}>{t}</option>)}</select></Field>
            <Field label="Name *"><input required value={form.firstName} onChange={set('firstName')} /></Field>
            <Field label="Surname *"><input required value={form.lastName} onChange={set('lastName')} /></Field>
            <Field label="Gender *">
              <select value={form.gender} onChange={set('gender')}>{['male', 'female', 'other'].map((g) => <option key={g}>{g}</option>)}</select>
            </Field>
            <Field label="Username *"><input required autoComplete="off" value={form.username} onChange={set('username')} /></Field>
            <Field label="Mobile"><input value={form.mobile} onChange={set('mobile')} /></Field>
            <Field label="Password"><PasswordInput autoComplete="new-password" placeholder="Empty = default password" value={form.password} onChange={set('password')} /></Field>
            <Field label="Confirm password"><PasswordInput autoComplete="new-password" value={form.confirmPassword} onChange={set('confirmPassword')} /></Field>
            <Field label="Department">
              <select value={form.departmentId} onChange={set('departmentId')}>
                <option value="">-</option>
                {departments.map((d) => <option key={d.departmentId} value={d.departmentId}>{d.deptName}</option>)}
              </select>
            </Field>
            <Field label="Roles" wide>
              <div style={{ display: 'flex', flexWrap: 'wrap', gap: '6px 16px' }}>
                {roleCodes.map((code) => (
                  <label key={code} style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 14, color: 'var(--ink)' }}>
                    <input type="checkbox" style={{ width: 'auto' }} checked={form.roles.includes(code)} onChange={() => toggleRole(code)} />
                    {roleLabel(code)}
                  </label>
                ))}
              </div>
            </Field>
          </div>
          <p className="muted">
            The password is used for both WSO2 Identity Server and the HIMS login: 8-64 characters with an uppercase letter, a lowercase
            letter, a digit and a special character. Leave it empty to use the default password set by the administrator.
          </p>
          <button type="submit" disabled={busy || branches.length === 0}>{busy ? 'Creating...' : 'Add user'}</button>
          {msg && <Alert kind={msg.kind}>{msg.text}</Alert>}
        </form>
      </Card>

      <Card title={`Users (${users.length})`} actions={<button className="secondary" onClick={load}>Refresh</button>}>
        <table>
          <thead><tr><th>Code</th><th>Name</th><th>Username</th><th>Mobile</th><th>Branch</th><th>Department</th><th>Roles</th><th>Status</th><th>Last login</th></tr></thead>
          <tbody>
            {users.map((u) => (
              <tr key={u.userId}>
                <td>{u.employeeCode ?? '-'}</td>
                <td>{[u.firstName, u.lastName].filter(Boolean).join(' ') || '-'}</td>
                <td>{u.username}</td>
                <td>{u.mobile ?? ''}</td>
                <td>{branchName(u.branchId)}</td>
                <td>{deptName(u.departmentId)}</td>
                <td>{u.roles.map((r) => <span key={r} style={{ marginRight: 4 }}><Badge tone="blue">{roleLabel(r)}</Badge></span>)}</td>
                <td>{u.isLocked ? <Badge tone="red">Locked</Badge> : u.isActive ? <Badge tone="green">Active</Badge> : <Badge>Inactive</Badge>}</td>
                <td className="muted">{u.lastLoginAt ? new Date(u.lastLoginAt).toLocaleString() : 'never'}</td>
              </tr>
            ))}
            {users.length === 0 && <tr><td colSpan={9} className="muted">No users yet.</td></tr>}
          </tbody>
        </table>
      </Card>
    </>
  );
}

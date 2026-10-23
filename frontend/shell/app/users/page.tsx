'use client';
import { FormEvent, useEffect, useState } from 'react';
import { API, api, errMsg } from '@/lib/api';
import { Alert, Badge, Card, Field } from '@/components/ui';
import PasswordInput from '@/components/PasswordInput';
import { PASSWORD_RULE, passwordProblem } from '@/lib/password';

// Staff users (Identity & Org). Adding one creates the employee with its roles and notifies the other services (EmployeeUpdated ->
// their ref.employee). With Portal Access it also creates the login: the user in the organization's WSO2 Identity Server tenant and
// the HIMS username and password, linked to each other. "Generate Username and Password" fills both in for the admin to hand over.

type User = {
  userId?: number; username?: string; portalAccess: boolean; isActive: boolean; isLocked: boolean; lastLoginAt?: string; createdAt: string;
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
  branchId: '', title: 'Mr', firstName: '', lastName: '', gender: 'male', mobile: '', departmentId: '',
  roles: [] as string[], portalAccess: false, generate: false, username: '', password: '', confirmPassword: '',
};
const noLogin = { generate: false, username: '', password: '', confirmPassword: '' };

// Generated username: name.surname in lower case (letters and digits only), with a number added when it is taken.
function generateUsername(firstName: string, lastName: string, taken: Set<string>) {
  const part = (s: string) => s.toLowerCase().replace(/[^a-z0-9]/g, '');
  const base = [part(firstName), part(lastName)].filter(Boolean).join('.') || 'user';
  let name = base;
  for (let i = 2; taken.has(name); i++) name = base + i;
  return name;
}

// Generated password meeting the password policy: 12 characters with upper and lower case letters, digits and special characters.
function generatePassword() {
  const sets = ['ABCDEFGHJKLMNPQRSTUVWXYZ', 'abcdefghijkmnopqrstuvwxyz', '23456789', '@#$%&*!?'];
  const random = (n: number) => crypto.getRandomValues(new Uint32Array(1))[0] % n;
  const pick = (chars: string) => chars[random(chars.length)];
  const chars = [...sets.map(pick), ...Array.from({ length: 8 }, () => pick(sets.join('')))];
  for (let i = chars.length - 1; i > 0; i--) {   // shuffle, so the required characters are not always first
    const j = random(i + 1);
    [chars[i], chars[j]] = [chars[j], chars[i]];
  }
  return chars.join('');
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

  const takenUsernames = new Set(users.map((u) => u.username?.toLowerCase()).filter(Boolean) as string[]);
  const set = (k: Exclude<keyof typeof emptyForm, 'roles' | 'portalAccess' | 'generate'>) => (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    const next = { ...form, [k]: e.target.value };
    // A generated username follows the name and surname.
    if (form.generate && (k === 'firstName' || k === 'lastName')) next.username = generateUsername(next.firstName, next.lastName, takenUsernames);
    setForm(next);
  };
  const setGenerate = (on: boolean) => {
    const password = on ? generatePassword() : '';
    setForm(on ? { ...form, generate: true, username: generateUsername(form.firstName, form.lastName, takenUsernames), password, confirmPassword: password }
               : { ...form, ...noLogin });
  };
  const toggleRole = (code: string) => setForm({ ...form, roles: form.roles.includes(code) ? form.roles.filter((r) => r !== code) : [...form.roles, code] });

  async function submit(e: FormEvent) {
    e.preventDefault();
    setMsg(null);
    if (!form.firstName.trim() || !form.lastName.trim()) { setMsg({ kind: 'error', text: 'Enter the name and surname.' }); return; }
    if (form.portalAccess) {   // the login's username and password are needed only with portal access
      const problem = !form.username.trim() ? 'Enter a username.'
        : /\s/.test(form.username.trim()) ? 'Username must not contain spaces.'
        : !form.password ? 'Enter a password.'
        : !form.confirmPassword ? 'Confirm the password.'
        : passwordProblem(form.password) ?? (form.password !== form.confirmPassword ? 'The passwords do not match.' : null);
      if (problem) { setMsg({ kind: 'error', text: problem }); return; }
    }
    setBusy(true);
    try {
      const r = await api<any>(API.identityOrg, '/api/users', {
        body: {
          branchId: Number(form.branchId), title: form.title, firstName: form.firstName, lastName: form.lastName, gender: form.gender,
          mobile: form.mobile || null, departmentId: form.departmentId ? Number(form.departmentId) : null, roles: form.roles,
          portalAccess: form.portalAccess, ...(form.portalAccess ? { username: form.username.trim(), password: form.password } : {}),
        },
      });
      const generated = form.portalAccess && form.generate ? ` Generated sign-in: username ${r.username}, password ${form.password} - give these to the user.` : '';
      setMsg({ kind: 'ok', text: (r.portalAccess
        ? `User ${r.username} created: employee ${r.employeeCode}${r.wso2 ? `, WSO2 user in ${r.wso2.tenant}` : ''}.`
        : `Employee ${r.employeeCode} created without portal access.`) + generated + ' The other services receive the employee within a few seconds.' });
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
            <Field label="Mobile"><input value={form.mobile} onChange={set('mobile')} /></Field>
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
            <label className="field wide" style={{ flexDirection: 'row', alignItems: 'center', gap: 8, fontSize: 14, color: 'var(--ink)' }}>
              <input id="portal-access" type="checkbox" style={{ width: 'auto' }} checked={form.portalAccess}
                onChange={(e) => setForm({ ...form, ...noLogin, portalAccess: e.target.checked })} />
              <strong>Portal Access</strong>
              <span className="muted" style={{ fontSize: 13 }}>- a login for WSO2 Identity Server and HIMS</span>
            </label>
            {form.portalAccess && (
              <>
                <label className="field wide" style={{ flexDirection: 'row', alignItems: 'center', gap: 8, fontSize: 14, color: 'var(--ink)', paddingLeft: 24 }}>
                  <input id="generate-credentials" type="checkbox" style={{ width: 'auto' }} checked={form.generate} onChange={(e) => setGenerate(e.target.checked)} />
                  <strong>Generate Username and Password</strong>
                  {form.generate && <button type="button" className="secondary" style={{ marginLeft: 8 }} onClick={() => setGenerate(true)}>Generate again</button>}
                </label>
                <Field label="Username *"><input id="username" autoComplete="off" readOnly={form.generate} value={form.username} onChange={set('username')} /></Field>
                <Field label="Password *"><PasswordInput id="password" autoComplete="new-password" readOnly={form.generate} value={form.password} onChange={set('password')} /></Field>
                <Field label="Confirm password *"><PasswordInput id="confirm-password" autoComplete="new-password" readOnly={form.generate} value={form.confirmPassword} onChange={set('confirmPassword')} /></Field>
              </>
            )}
          </div>
          {form.portalAccess && (
            <p className="muted">
              The username and password are created in WSO2 Identity Server and in HIMS. Password: {PASSWORD_RULE}
            </p>
          )}
          <button type="submit" disabled={busy || branches.length === 0}>{busy ? 'Creating...' : 'Add user'}</button>
          {msg && <Alert kind={msg.kind}>{msg.text}</Alert>}
        </form>
      </Card>

      <Card title={`Users (${users.length})`} actions={<button className="secondary" onClick={load}>Refresh</button>}>
        <table>
          <thead><tr><th>Code</th><th>Name</th><th>Portal Access</th><th>Username</th><th>Mobile</th><th>Branch</th><th>Department</th><th>Roles</th><th>Status</th><th>Last login</th></tr></thead>
          <tbody>
            {users.map((u) => (
              <tr key={u.userId ?? `e${u.employeeId}`}>
                <td>{u.employeeCode ?? '-'}</td>
                <td>{[u.firstName, u.lastName].filter(Boolean).join(' ') || '-'}</td>
                <td>{u.portalAccess ? <Badge tone="green">Yes</Badge> : <Badge>No</Badge>}</td>
                <td>{u.username ?? '-'}</td>
                <td>{u.mobile ?? ''}</td>
                <td>{branchName(u.branchId)}</td>
                <td>{deptName(u.departmentId)}</td>
                <td>{u.roles.map((r) => <span key={r} style={{ marginRight: 4 }}><Badge tone="blue">{roleLabel(r)}</Badge></span>)}</td>
                <td>{u.isLocked ? <Badge tone="red">Locked</Badge> : u.isActive ? <Badge tone="green">Active</Badge> : <Badge>Inactive</Badge>}</td>
                <td className="muted">{!u.userId ? '-' : u.lastLoginAt ? new Date(u.lastLoginAt).toLocaleString() : 'never'}</td>
              </tr>
            ))}
            {users.length === 0 && <tr><td colSpan={10} className="muted">No users yet.</td></tr>}
          </tbody>
        </table>
      </Card>
    </>
  );
}

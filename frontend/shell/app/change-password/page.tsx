'use client';
import { FormEvent, useState } from 'react';
import { API, api, errMsg } from '@/lib/api';
import { PASSWORD_RULE, passwordProblem } from '@/lib/password';
import { Alert, Card, Field } from '@/components/ui';
import PasswordInput from '@/components/PasswordInput';

// The signed-in user changes their own password. Identity & Org changes it in WSO2 Identity Server (the user's tenant) and in
// HIMS (sec.user_account); the result says where it was changed.
export default function ChangePassword() {
  const [password, setPassword] = useState('');
  const [confirm, setConfirm] = useState('');
  const [msg, setMsg] = useState<{ kind: 'ok' | 'error'; text: string } | null>(null);
  const [busy, setBusy] = useState(false);

  function problem(): string | null {
    if (!password) return 'Enter the new password.';
    if (!confirm) return 'Confirm the new password.';
    const p = passwordProblem(password);
    if (p) return p;
    if (password !== confirm) return 'The passwords do not match.';
    return null;
  }

  async function submit(e: FormEvent) {
    e.preventDefault();
    const p = problem();
    if (p) { setMsg({ kind: 'error', text: p }); return; }
    setBusy(true); setMsg(null);
    try {
      const r = await api<{ username: string; hims: string; wso2: string }>(API.identityOrg, '/api/account/password', { body: { newPassword: password } });
      setMsg({ kind: 'ok', text: `Password changed for ${r.username}: ${r.wso2}; ${r.hims}.` });
      setPassword(''); setConfirm('');
    } catch (err) { setMsg({ kind: 'error', text: errMsg(err) }); }
    setBusy(false);
  }

  return (
    <div style={{ maxWidth: 460, margin: '24px auto' }}>
      <h1>Change password</h1>
      <Card>
        <form onSubmit={submit} noValidate style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          <Field label="New password *">
            <PasswordInput id="new-password" autoComplete="new-password" autoFocus value={password} onChange={(e) => setPassword(e.target.value)} />
          </Field>
          <Field label="Confirm password *">
            <PasswordInput id="confirm-password" autoComplete="new-password" value={confirm} onChange={(e) => setConfirm(e.target.value)} />
          </Field>
          <p className="muted" style={{ margin: 0 }}>{PASSWORD_RULE} The password is changed in WSO2 Identity Server and in HIMS.</p>
          {msg && <Alert kind={msg.kind}>{msg.text}</Alert>}
          <button type="submit" disabled={busy}>{busy ? 'Changing...' : 'Submit'}</button>
        </form>
      </Card>
    </div>
  );
}

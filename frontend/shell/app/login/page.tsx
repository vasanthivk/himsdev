'use client';
import { FormEvent, useEffect, useState } from 'react';
import { API } from '@/lib/api';
import { HIMS_LOGIN, safeReturnTo, storeHimsSession } from '@/lib/auth';
import { Alert, Card, Field } from '@/components/ui';
import PasswordInput from '@/components/PasswordInput';

// HIMS's own sign-in (WSO2_AUTHENTICATION=false): username + password against Identity & Org's POST /api/auth/login, which
// returns a HIMS access token. With WSO2 sign-in this page just forwards to the home page.
export default function Login() {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  useEffect(() => { if (!HIMS_LOGIN) window.location.replace('/'); }, []);

  async function submit(e: FormEvent) {
    e.preventDefault();
    setBusy(true); setError(null);
    try {
      const res = await fetch(`${API.identityOrg}/api/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username, password }),
      });
      const data = await res.json().catch(() => ({}));
      if (!res.ok) throw new Error(data.error ?? `Sign-in failed (${res.status})`);
      storeHimsSession(data);
      window.location.replace(safeReturnTo(new URLSearchParams(window.location.search).get('returnTo')));
    } catch (err) {
      setError(err instanceof TypeError ? 'Cannot reach the Identity & Org service - is it running?' : err instanceof Error ? err.message : String(err));
      setBusy(false);
    }
  }

  if (!HIMS_LOGIN) return null;
  return (
    <div style={{ maxWidth: 420, margin: '40px auto' }}>
      <Card title="Sign in to HIMS">
        <form onSubmit={submit} style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          <Field label="Username"><input autoFocus autoComplete="username" required value={username} onChange={(e) => setUsername(e.target.value)} /></Field>
          <Field label="Password"><PasswordInput autoComplete="current-password" required value={password} onChange={(e) => setPassword(e.target.value)} /></Field>
          {error && <Alert kind="error">{error}</Alert>}
          <button type="submit" disabled={busy}>{busy ? 'Signing in...' : 'Sign in'}</button>
        </form>
      </Card>
    </div>
  );
}

'use client';
import { useEffect, useState } from 'react';
import Nav from '@/components/Nav';
import ProfileMenu from '@/components/ProfileMenu';
import { Alert } from '@/components/ui';
import { CALLBACK_PATH, getAccessToken, getAuthConfig, getUser, login, User } from '@/lib/auth';

type Gate = { phase: 'checking' } | { phase: 'ready'; user: User | null } | { phase: 'error'; message: string };

// Renders the nav and the page only once the user is signed in to the WSO2 Identity Server tenant of this subdomain; otherwise
// sends them to its login page. The OIDC callback page is never gated.
export default function AuthGate({ active, children }: { active: string; children: React.ReactNode }) {
  const [gate, setGate] = useState<Gate>({ phase: 'checking' });

  useEffect(() => {
    (async () => {
      const cfg = await getAuthConfig();
      if (cfg.status === 'disabled' || window.location.pathname.startsWith(CALLBACK_PATH)) return setGate({ phase: 'ready', user: null });
      if (cfg.status === 'unknown-tenant') return setGate({ phase: 'error', message: `No WSO2 login is configured for ${cfg.host}.` });
      if (!(await getAccessToken())) return login();
      setGate({ phase: 'ready', user: getUser() });
    })().catch((e) => setGate({ phase: 'error', message: e instanceof Error ? e.message : String(e) }));
  }, []);

  if (gate.phase === 'checking') return <main><p className="muted">Signing in...</p></main>;
  if (gate.phase === 'error') return <main><Alert kind="error">{gate.message}</Alert></main>;
  return (
    <>
      <Nav active={active} user={gate.user && <ProfileMenu user={gate.user} />} />
      <main>{children}</main>
    </>
  );
}

'use client';
import { useEffect, useRef, useState } from 'react';
import { handleCallback } from '@/lib/auth';
import { Alert, Card } from '@/components/ui';

// WSO2 IS redirects here after login and after sign-out. Each tenant's WSO2 application registers its own subdomain's URL,
// e.g. https://reddys.localhost:3000/sign-in-oidc and https://apollo.localhost:3000/sign-in-oidc.
export default function SignInOidc() {
  const [error, setError] = useState<string | null>(null);
  const started = useRef(false);   // React strict mode runs effects twice in dev; the code can be exchanged only once

  useEffect(() => {
    if (started.current) return;
    started.current = true;
    const params = new URLSearchParams(window.location.search);
    if (!params.has('code') && !params.has('error')) { window.location.replace('/'); return; }   // back from sign-out
    handleCallback().then((to) => window.location.replace(to)).catch((e) => setError(e instanceof Error ? e.message : String(e)));
  }, []);

  return (
    <Card title="Signing in">
      {error ? <><Alert kind="error">{error}</Alert><a href="/">Try again</a></> : <p className="muted">Completing sign-in...</p>}
    </Card>
  );
}

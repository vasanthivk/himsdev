import { NextRequest, NextResponse } from 'next/server';

// WSO2 Identity Server settings for the tenant the browser is on. The tenant is the first label of the host name, in upper case:
// apollo.localhost:3000 -> APOLLO_WSO2_BASE_URL / APOLLO_WSO2_CLIENT_ID / APOLLO_WSO2_SCOPE from the shell's .env.
// Read per request (not inlined at build time), so a new tenant only needs its three lines in .env and a shell restart.
// Every zone is served through the shell, so the zones call this route too.
export const dynamic = 'force-dynamic';

const clean = (v: string | undefined) => (v ?? '').trim();

export function GET(req: NextRequest) {
  const host = (req.headers.get('x-forwarded-host') ?? req.headers.get('host') ?? '').split(',')[0].trim().split(':')[0].toLowerCase();
  const labels = host.split('.');
  const prefix = labels.length > 1 ? labels[0].toUpperCase().replace(/[^A-Z0-9]/g, '_') : '';

  const clientId = prefix ? clean(process.env[`${prefix}_WSO2_CLIENT_ID`]) : '';
  if (clientId) {
    return NextResponse.json({
      status: 'ok',
      tenant: prefix,
      baseUrl: clean(process.env[`${prefix}_WSO2_BASE_URL`]).replace(/\/+$/, ''),
      clientId,
      scope: clean(process.env[`${prefix}_WSO2_SCOPE`]) || 'openid profile email',
    });
  }

  // No tenant matches this host. If any tenant is configured, refuse (rather than letting the app open without login);
  // with no tenants configured at all, login is off (local development).
  const anyTenant = Object.keys(process.env).some((k) => k.endsWith('_WSO2_CLIENT_ID') && clean(process.env[k]));
  return NextResponse.json(anyTenant ? { status: 'unknown-tenant', host } : { status: 'disabled' });
}

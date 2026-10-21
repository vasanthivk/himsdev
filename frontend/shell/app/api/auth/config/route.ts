import { NextRequest, NextResponse } from 'next/server';
import { anyTenantConfigured, requestHost, tenantFor } from '@/lib/tenant';

// WSO2 Identity Server settings for the tenant the browser is on (see lib/tenant.ts). Read per request (not inlined at build
// time), so a new tenant only needs its lines in .env and a shell restart. Every zone is served through the shell, so the zones
// call this route too. Only public values are returned - the client secret stays on the server (see ../token/route.ts).
export const dynamic = 'force-dynamic';

export function GET(req: NextRequest) {
  const tenant = tenantFor(req);
  if (tenant) {
    return NextResponse.json({ status: 'ok', tenant: tenant.prefix, baseUrl: tenant.baseUrl, clientId: tenant.clientId, scope: tenant.scope });
  }
  // No tenant matches this host. If any tenant is configured, refuse (rather than letting the app open without login);
  // with no tenants configured at all, login is off (local development).
  return NextResponse.json(anyTenantConfigured() ? { status: 'unknown-tenant', host: requestHost(req) } : { status: 'disabled' });
}

// Server-side only (route handlers): resolves the WSO2 Identity Server tenant from the request's host name and reads its settings
// from the shell's .env. apollo.localhost:3000 -> APOLLO_WSO2_BASE_URL / _CLIENT_ID / _CLIENT_SECRET / _SCOPE.
import type { NextRequest } from 'next/server';

export type Tenant = { prefix: string; baseUrl: string; clientId: string; clientSecret: string; scope: string };

const clean = (v: string | undefined) => (v ?? '').trim();

export function requestHost(req: NextRequest): string {
  return (req.headers.get('x-forwarded-host') ?? req.headers.get('host') ?? '').split(',')[0].trim().split(':')[0].toLowerCase();
}

/** The tenant for this host, or null when no *_WSO2_CLIENT_ID is set for its subdomain. */
export function tenantFor(req: NextRequest): Tenant | null {
  const labels = requestHost(req).split('.');
  const prefix = labels.length > 1 ? labels[0].toUpperCase().replace(/[^A-Z0-9]/g, '_') : '';
  const clientId = prefix ? clean(process.env[`${prefix}_WSO2_CLIENT_ID`]) : '';
  if (!clientId) return null;
  return {
    prefix,
    baseUrl: clean(process.env[`${prefix}_WSO2_BASE_URL`]).replace(/\/+$/, ''),
    clientId,
    clientSecret: clean(process.env[`${prefix}_WSO2_CLIENT_SECRET`]),
    scope: clean(process.env[`${prefix}_WSO2_SCOPE`]) || 'openid profile email',
  };
}

/** True when any tenant is configured (then an unknown host is refused instead of running without login). */
export const anyTenantConfigured = () => Object.keys(process.env).some((k) => k.endsWith('_WSO2_CLIENT_ID') && clean(process.env[k]));

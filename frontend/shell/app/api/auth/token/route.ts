import https from 'node:https';
import { NextRequest, NextResponse } from 'next/server';
import { tenantFor } from '@/lib/tenant';

// Token endpoint proxy for the WSO2 Identity Server confidential client. The browser posts the authorization code (or a refresh
// token) here; the shell adds the tenant's client credentials as HTTP Basic auth - <PREFIX>_WSO2_CLIENT_ID / _CLIENT_SECRET from
// .env - and forwards the request to <PREFIX>_WSO2_BASE_URL/oauth2/token. The secret never reaches the browser.
// With no _CLIENT_SECRET for the tenant, the request is forwarded as a public client (client_id in the body, PKCE only).
export const dynamic = 'force-dynamic';

const ALLOWED_GRANTS = new Set(['authorization_code', 'refresh_token']);
const FORWARDED_FIELDS = ['grant_type', 'code', 'redirect_uri', 'code_verifier', 'refresh_token', 'scope'];

// Dev only: WSO2 IS ships with a self-signed certificate.
const agent = new https.Agent({ rejectUnauthorized: process.env.WSO2_ALLOW_UNTRUSTED_CERT !== 'true' });

function post(url: string, headers: Record<string, string>, body: string): Promise<{ status: number; text: string }> {
  return new Promise((resolve, reject) => {
    const req = https.request(url, { method: 'POST', agent, headers: { ...headers, 'Content-Length': Buffer.byteLength(body).toString() } }, (res) => {
      let text = '';
      res.setEncoding('utf8');
      res.on('data', (chunk) => (text += chunk));
      res.on('end', () => resolve({ status: res.statusCode ?? 502, text }));
    });
    req.on('error', reject);
    req.setTimeout(15000, () => req.destroy(new Error('WSO2 token endpoint timed out')));
    req.end(body);
  });
}

export async function POST(req: NextRequest) {
  const tenant = tenantFor(req);
  if (!tenant) return NextResponse.json({ error: 'invalid_request', error_description: 'No WSO2 login is configured for this host.' }, { status: 400 });

  const incoming = new URLSearchParams(await req.text());
  if (!ALLOWED_GRANTS.has(incoming.get('grant_type') ?? '')) {
    return NextResponse.json({ error: 'unsupported_grant_type', error_description: 'Only authorization_code and refresh_token are allowed.' }, { status: 400 });
  }
  const form = new URLSearchParams();
  for (const field of FORWARDED_FIELDS) { const v = incoming.get(field); if (v) form.set(field, v); }

  const headers: Record<string, string> = { 'Content-Type': 'application/x-www-form-urlencoded', Accept: 'application/json' };
  if (tenant.clientSecret) headers.Authorization = `Basic ${Buffer.from(`${tenant.clientId}:${tenant.clientSecret}`).toString('base64')}`;
  else form.set('client_id', tenant.clientId);

  try {
    const res = await post(`${tenant.baseUrl}/oauth2/token`, headers, form.toString());
    return new NextResponse(res.text, { status: res.status, headers: { 'Content-Type': 'application/json', 'Cache-Control': 'no-store' } });
  } catch (e) {
    return NextResponse.json({ error: 'server_error', error_description: `Cannot reach WSO2 Identity Server: ${e instanceof Error ? e.message : e}` }, { status: 502 });
  }
}

// WSO2 Identity Server sign-in (OpenID Connect authorization code flow + PKCE, public client). Shared by every zone (copied in by
// sync-shared.sh). The shell serves every zone from one origin, so the session in sessionStorage is seen by all of them.
// Multi-tenant: the WSO2 settings depend on the subdomain (apollo.localhost -> APOLLO_WSO2_*) and come from the shell's
// /api/auth/config route at runtime. Each subdomain is its own browser origin, so tenants never share a session.
export type AuthConfig =
  | { status: 'ok'; tenant: string; baseUrl: string; clientId: string; scope: string }
  | { status: 'unknown-tenant'; host: string }
  | { status: 'disabled' };

let configPromise: Promise<AuthConfig> | null = null;

/** The WSO2 settings for this host (fetched once per page load). */
export function getAuthConfig(): Promise<AuthConfig> {
  configPromise ??= fetch('/api/auth/config', { cache: 'no-store' })
    .then((r) => { if (!r.ok) throw new Error(`Login configuration not available (${r.status})`); return r.json(); })
    .catch((e) => { configPromise = null; throw e; });
  return configPromise;
}

async function tenantConfig() {
  const c = await getAuthConfig();
  if (c.status !== 'ok') throw new Error(c.status === 'unknown-tenant' ? `No WSO2 login is configured for ${c.host}.` : 'Login is turned off.');
  return c;
}

/** Path WSO2 IS redirects back to after login; must match the redirect URL registered on the WSO2 application. */
export const CALLBACK_PATH = '/sign-in-oidc';

const SESSION_KEY = 'hims.auth';
const LOGIN_KEY = 'hims.auth.login';

export type User = { sub: string; name: string; username?: string; email?: string; phone?: string; roles: string[] };
type Session = { accessToken: string; idToken: string; refreshToken?: string; expiresAt: number; user: User };

const redirectUri = () => `${window.location.origin}${CALLBACK_PATH}`;
const b64url = (bytes: Uint8Array) => btoa(String.fromCharCode(...bytes)).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
const randomString = (n: number) => b64url(crypto.getRandomValues(new Uint8Array(n)));
const sha256 = async (s: string) => b64url(new Uint8Array(await crypto.subtle.digest('SHA-256', new TextEncoder().encode(s))));
const jwtClaims = (jwt: string) =>
  JSON.parse(new TextDecoder().decode(Uint8Array.from(atob(jwt.split('.')[1].replace(/-/g, '+').replace(/_/g, '/')), (c) => c.charCodeAt(0))));

function readSession(): Session | null {
  try { return JSON.parse(sessionStorage.getItem(SESSION_KEY) ?? 'null'); } catch { return null; }
}

function storeSession(t: any, prev?: Session): Session {
  const idToken: string = t.id_token ?? prev?.idToken;
  const c = jwtClaims(idToken);
  const roles = c.roles ?? c.groups ?? [];
  const session: Session = {
    accessToken: t.access_token,
    idToken,
    refreshToken: t.refresh_token ?? prev?.refreshToken,
    expiresAt: Date.now() + (Number(t.expires_in ?? 3600) - 30) * 1000,
    user: {
      sub: c.sub,
      name: c.name ?? ([c.given_name, c.family_name].filter(Boolean).join(' ') || c.username || c.sub),
      username: c.username ?? c.preferred_username,
      email: c.email,
      phone: c.phone_number,
      roles: Array.isArray(roles) ? roles : String(roles).split(','),
    },
  };
  sessionStorage.setItem(SESSION_KEY, JSON.stringify(session));
  return session;
}

// Token requests go to the shell's /api/auth/token, which adds the tenant's client secret (HTTP Basic) on the server and forwards
// them to WSO2 IS - the secret never reaches the browser.
async function tokenRequest(body: Record<string, string>) {
  await tenantConfig();
  const res = await fetch('/api/auth/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams(body),
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data.error_description ?? data.error ?? `Token request failed (${res.status})`);
  return data;
}

export const getUser = (): User | null => readSession()?.user ?? null;

let refreshing: Promise<Session | null> | null = null;

/** A valid access token (refreshed when expired), or null when the user has to sign in. */
export async function getAccessToken(): Promise<string | null> {
  const cfg = await getAuthConfig().catch(() => null);
  if (cfg?.status !== 'ok') return null;
  const s = readSession();
  if (!s) return null;
  if (s.expiresAt > Date.now()) return s.accessToken;
  if (!s.refreshToken) return null;
  refreshing ??= tokenRequest({ grant_type: 'refresh_token', refresh_token: s.refreshToken })
    .then((t) => storeSession(t, s))
    .catch(() => { sessionStorage.removeItem(SESSION_KEY); return null; })
    .finally(() => { refreshing = null; });
  return (await refreshing)?.accessToken ?? null;
}

/** Sends the browser to the WSO2 IS login page; it comes back to CALLBACK_PATH and then to returnTo. */
export async function login(returnTo = window.location.pathname + window.location.search) {
  const cfg = await tenantConfig();
  const verifier = randomString(48), state = randomString(16), nonce = randomString(16);
  sessionStorage.setItem(LOGIN_KEY, JSON.stringify({ verifier, state, nonce, returnTo }));
  const q = new URLSearchParams({
    response_type: 'code', client_id: cfg.clientId, redirect_uri: redirectUri(), scope: cfg.scope, state, nonce,
    code_challenge: await sha256(verifier), code_challenge_method: 'S256',
  });
  window.location.assign(`${cfg.baseUrl}/oauth2/authorize?${q}`);
}

/** Runs on CALLBACK_PATH: exchanges the code for tokens and returns the path to go back to. */
export async function handleCallback(): Promise<string> {
  const p = new URLSearchParams(window.location.search);
  const saved = JSON.parse(sessionStorage.getItem(LOGIN_KEY) ?? 'null');
  sessionStorage.removeItem(LOGIN_KEY);
  if (p.get('error')) throw new Error(p.get('error_description') ?? p.get('error')!);
  if (!saved || p.get('state') !== saved.state) throw new Error('Login state mismatch - please sign in again.');
  const tokens = await tokenRequest({ grant_type: 'authorization_code', code: p.get('code') ?? '', redirect_uri: redirectUri(), code_verifier: saved.verifier });
  if (jwtClaims(tokens.id_token).nonce !== saved.nonce) throw new Error('Login nonce mismatch - please sign in again.');
  storeSession(tokens);
  const to: string = saved.returnTo ?? '/';
  return to.startsWith('/') && !to.startsWith('//') ? to : '/';
}

/** Clears the local session and ends the tenant's WSO2 IS session (single logout). */
export async function logout() {
  const cfg = await tenantConfig();
  const s = readSession();
  sessionStorage.removeItem(SESSION_KEY);
  sessionStorage.removeItem(LOGIN_KEY);
  // WSO2 IS only accepts a post-logout URI that matches the app's registered callback URL, so return to the callback page;
  // without a code in the URL it forwards to "/".
  const q = new URLSearchParams({ client_id: cfg.clientId, post_logout_redirect_uri: redirectUri() });
  if (s) q.set('id_token_hint', s.idToken);
  window.location.assign(`${cfg.baseUrl}/oidc/logout?${q}`);
}

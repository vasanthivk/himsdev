import { getAccessToken } from '@/lib/auth';

// Shared by every zone (copied into each one - see frontend/README.md). All URLs come from each app's .env; they are inlined at
// build / dev start, so each variable is named literally here (WSO2_AUTHENTICATION is passed through by next.config.js).
//
// WSO2_AUTHENTICATION=true  -> calls go through the WSO2 API Manager gateway, one published API per service (NEXT_PUBLIC_*_API):
//                              the gateway validates the user's WSO2 IS token and subscription, then calls the service with a
//                              signed backend JWT (X-JWT-Assertion).
// WSO2_AUTHENTICATION=false -> calls go straight to the services' own addresses (NEXT_PUBLIC_*_SERVICE). The services must then
//                              run with Auth:Enabled=false, since only the gateway can produce the JWT they require.
// The Integration Hub is not published on the gateway, so it is always called on its own address.

/** A required .env value: fails loudly instead of calling "undefined/api/...". */
function env(name: string, value: string | undefined): string {
  if (!value) throw new Error(`${name} is not set - add it to this app's .env and restart it.`);
  return value.replace(/\/+$/, '');
}

const wso2Authentication = env('WSO2_AUTHENTICATION', process.env.WSO2_AUTHENTICATION).toLowerCase();
if (wso2Authentication !== 'true' && wso2Authentication !== 'false') {
  throw new Error(`WSO2_AUTHENTICATION must be true or false (it is "${wso2Authentication}").`);
}
export const WSO2_AUTHENTICATION = wso2Authentication === 'true';

/** Base URL of each backend: the WSO2 gateway API when WSO2_AUTHENTICATION=true, otherwise the service's own address. */
export const API = WSO2_AUTHENTICATION
  ? {
      patientAccess: env('NEXT_PUBLIC_PATIENT_ACCESS_API', process.env.NEXT_PUBLIC_PATIENT_ACCESS_API),
      clinicalCare: env('NEXT_PUBLIC_CLINICAL_CARE_API', process.env.NEXT_PUBLIC_CLINICAL_CARE_API),
      laboratory: env('NEXT_PUBLIC_LABORATORY_API', process.env.NEXT_PUBLIC_LABORATORY_API),
      revenueCycle: env('NEXT_PUBLIC_REVENUE_CYCLE_API', process.env.NEXT_PUBLIC_REVENUE_CYCLE_API),
      identityOrg: env('NEXT_PUBLIC_IDENTITY_ORG_API', process.env.NEXT_PUBLIC_IDENTITY_ORG_API),
      integration: env('NEXT_PUBLIC_INTEGRATION_SERVICE', process.env.NEXT_PUBLIC_INTEGRATION_SERVICE),
    }
  : {
      patientAccess: env('NEXT_PUBLIC_PATIENT_ACCESS_SERVICE', process.env.NEXT_PUBLIC_PATIENT_ACCESS_SERVICE),
      clinicalCare: env('NEXT_PUBLIC_CLINICAL_CARE_SERVICE', process.env.NEXT_PUBLIC_CLINICAL_CARE_SERVICE),
      laboratory: env('NEXT_PUBLIC_LABORATORY_SERVICE', process.env.NEXT_PUBLIC_LABORATORY_SERVICE),
      revenueCycle: env('NEXT_PUBLIC_REVENUE_CYCLE_SERVICE', process.env.NEXT_PUBLIC_REVENUE_CYCLE_SERVICE),
      identityOrg: env('NEXT_PUBLIC_IDENTITY_ORG_SERVICE', process.env.NEXT_PUBLIC_IDENTITY_ORG_SERVICE),
      integration: env('NEXT_PUBLIC_INTEGRATION_SERVICE', process.env.NEXT_PUBLIC_INTEGRATION_SERVICE),
    };

export class ApiError extends Error {
  constructor(public status: number, message: string, public data?: any) {
    super(message);
  }
}

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

type Opts = { method?: string; body?: unknown; retry409?: boolean };

/**
 * JSON call to a microservice. With retry409 a 409 is retried for ~9 s: services answer 409 while an event from another service
 * (e.g. PatientRegistered) has not been replicated into their ref.* tables yet - the data model is eventually consistent.
 */
export async function api<T = any>(base: string, path: string, opts: Opts = {}): Promise<T> {
  const attempts = opts.retry409 ? 7 : 1;
  for (let i = 0; i < attempts; i++) {
    const hasBody = opts.body !== undefined;
    const headers: Record<string, string> = {};
    if (hasBody) headers['Content-Type'] = 'application/json';
    const token = await getAccessToken();
    if (token) headers.Authorization = `Bearer ${token}`;
    const res = await fetch(base + path, {
      method: opts.method ?? (hasBody ? 'POST' : 'GET'),
      headers,
      body: hasBody ? JSON.stringify(opts.body) : undefined,
    });
    if (res.status === 409 && i < attempts - 1) { await sleep(1500); continue; }
    const text = await res.text();
    let data: any = null;
    try { data = text ? JSON.parse(text) : null; } catch { data = text; }
    // The gateway answers with { code, message, description } (e.g. 900901 Invalid Credentials, 900908 Resource forbidden).
    const reason = data?.error ?? data?.detail ?? data?.title ?? data?.description ?? data?.message;
    if (res.status === 401) throw new ApiError(401, `Not signed in or the session has expired - sign out and sign in again.${reason ? ` (${reason})` : ''}`, data);
    if (res.status === 403) throw new ApiError(403, `You are not allowed to do this.${reason ? ` (${reason})` : ''}`, data);
    if (!res.ok) throw new ApiError(res.status, reason ?? res.statusText, data);
    return data as T;
  }
  throw new ApiError(0, 'unreachable');
}

export function errMsg(e: unknown): string {
  if (e instanceof ApiError) return e.message;
  if (e instanceof TypeError) return 'Cannot reach the service - is it running? (' + e.message + ')';
  return String(e);
}

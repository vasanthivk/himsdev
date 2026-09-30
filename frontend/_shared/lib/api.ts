// Shared by every zone (copied into each one - see frontend/README.md). Each microservice is called directly from the browser.
export const API = {
  patientAccess: process.env.NEXT_PUBLIC_PATIENT_ACCESS_API ?? 'http://localhost:5001',
  clinicalCare: process.env.NEXT_PUBLIC_CLINICAL_CARE_API ?? 'http://localhost:5002',
  laboratory: process.env.NEXT_PUBLIC_LABORATORY_API ?? 'http://localhost:5003',
  revenueCycle: process.env.NEXT_PUBLIC_REVENUE_CYCLE_API ?? 'http://localhost:5006',
  identityOrg: process.env.NEXT_PUBLIC_IDENTITY_ORG_API ?? 'http://localhost:5010',
  integration: process.env.NEXT_PUBLIC_INTEGRATION_API ?? 'http://localhost:5011',
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
    const res = await fetch(base + path, {
      method: opts.method ?? (hasBody ? 'POST' : 'GET'),
      headers: hasBody ? { 'Content-Type': 'application/json' } : undefined,
      body: hasBody ? JSON.stringify(opts.body) : undefined,
    });
    if (res.status === 409 && i < attempts - 1) { await sleep(1500); continue; }
    const text = await res.text();
    let data: any = null;
    try { data = text ? JSON.parse(text) : null; } catch { data = text; }
    if (!res.ok) throw new ApiError(res.status, data?.error ?? data?.detail ?? data?.title ?? res.statusText, data);
    return data as T;
  }
  throw new ApiError(0, 'unreachable');
}

export function errMsg(e: unknown): string {
  if (e instanceof ApiError) return e.message;
  if (e instanceof TypeError) return 'Cannot reach the service - is it running? (' + e.message + ')';
  return String(e);
}

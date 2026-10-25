import React from 'react';

export function Card({ title, children, actions }: { title?: string; children: React.ReactNode; actions?: React.ReactNode }) {
  return (
    <section className="card">
      {(title || actions) && (
        <div className="card-head">
          <h2>{title}</h2>
          <div>{actions}</div>
        </div>
      )}
      {children}
    </section>
  );
}

export function Alert({ kind = 'info', children }: { kind?: 'info' | 'ok' | 'warn' | 'error'; children: React.ReactNode }) {
  return <div className={`alert ${kind}`}>{children}</div>;
}

export function Badge({ tone = 'grey', children }: { tone?: 'grey' | 'green' | 'amber' | 'red' | 'blue'; children: React.ReactNode }) {
  return <span className={`badge ${tone}`}>{children}</span>;
}

export function Field({ label, children, wide }: { label: string; children: React.ReactNode; wide?: boolean }) {
  return (
    <label className={`field${wide ? ' wide' : ''}`}>
      <span>{label}</span>
      {children}
    </label>
  );
}

export const money = (n: number | null | undefined) => (n == null ? '-' : '₹' + Number(n).toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 }));
export const when = (iso?: string | null) => (iso ? new Date(iso).toLocaleString() : '-');
export const fullName = (p: any) => [p?.title, p?.firstName, p?.middleName, p?.lastName].filter(Boolean).join(' ');

export function statusTone(s?: string): 'grey' | 'green' | 'amber' | 'red' | 'blue' {
  switch ((s ?? '').toUpperCase()) {
    case 'SETTLED': case 'COMPLETED': case 'VERIFIED': case 'RELEASED': case 'PROVISIONED': case 'ONLINE': return 'green';
    case 'PARTIALLY_PAID': case 'FINALISED': case 'PENDING': case 'ORDERED': case 'OPEN': case 'IN_PROGRESS': case 'IN_PROCESS': return 'amber';
    case 'CANCELLED': case 'FAILED': return 'red';
    case 'RECEIVED': case 'SAMPLE_COLLECTED': return 'blue';
    default: return 'grey';
  }
}

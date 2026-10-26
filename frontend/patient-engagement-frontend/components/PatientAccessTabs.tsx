'use client';
import Link from 'next/link';
import { usePathname } from 'next/navigation';

// Patient Access has two pages: registering a new patient (/patient-engagement) and finding a registered patient to start an
// OP visit (/patient-engagement/visit). Links are relative to the zone's basePath.
const tabs = [
  { href: '/', label: 'Register patient' },
  { href: '/visit', label: 'Find patient / Start visit' },
];

export default function PatientAccessTabs() {
  const path = usePathname();   // without the basePath, e.g. "/" or "/visit"
  return (
    <nav className="subnav" aria-label="Patient Access">
      {tabs.map((t) => {
        const active = t.href === '/' ? path === '/' : path.startsWith(t.href);
        return (
          <Link key={t.href} href={t.href} className={active ? 'active' : ''} aria-current={active ? 'page' : undefined}>{t.label}</Link>
        );
      })}
    </nav>
  );
}

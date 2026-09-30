// Cross-zone links are plain <a> tags on purpose: each zone is a separate Next.js app, so navigating between them is a full page load.
const links = [
  { href: '/', label: 'Home', key: 'home' },
  { href: '/patient-access', label: 'Patient Access', key: 'patient-access' },
  { href: '/revenue-cycle', label: 'Billing', key: 'revenue-cycle' },
  { href: '/clinical-care', label: 'Doctor', key: 'clinical-care' },
  { href: '/laboratory', label: 'Laboratory', key: 'laboratory' },
];

export default function Nav({ active }: { active: string }) {
  return (
    <header className="nav">
      <a className="brand" href="/">HIMS <small>Dr Reddis HealthCare</small></a>
      <nav>
        {links.map((l) => (
          <a key={l.key} href={l.href} className={l.key === active ? 'active' : ''}>{l.label}</a>
        ))}
      </nav>
    </header>
  );
}

// Cross-zone links are plain <a> tags on purpose: each zone is a separate Next.js app, so navigating between them is a full page load.
const links = [
  { href: '/', label: 'Home', key: 'home' },
  { href: '/patient-engagement', label: 'Patient Access', key: 'patient-engagement' },
  { href: '/revenue-finance', label: 'Billing', key: 'revenue-finance' },
  { href: '/clinical-care', label: 'Doctor', key: 'clinical-care' },
  { href: '/diagnostics', label: 'Laboratory', key: 'diagnostics' },
  { href: '/users', label: 'Users', key: 'users' },
];

export default function Nav({ active, user }: { active: string; user?: React.ReactNode }) {
  return (
    <header className="nav">
      <a className="brand" href="/">HIMS <small>Dr Reddis HealthCare</small></a>
      <nav>
        {links.map((l) => (
          <a key={l.key} href={l.href} className={l.key === active ? 'active' : ''}>{l.label}</a>
        ))}
      </nav>
      {user}
    </header>
  );
}

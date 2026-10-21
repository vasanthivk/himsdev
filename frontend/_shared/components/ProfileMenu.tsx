'use client';
import { useEffect, useRef, useState } from 'react';
import { logout, User } from '@/lib/auth';

const initials = (name: string) => name.split(/[\s@._-]+/).filter(Boolean).slice(0, 2).map((p) => p[0].toUpperCase()).join('') || '?';

// Profile icon at the top right of the nav: click shows the signed-in user's WSO2 profile and Sign out.
export default function ProfileMenu({ user }: { user: User }) {
  const [open, setOpen] = useState(false);
  const [signingOut, setSigningOut] = useState(false);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!open) return;
    const close = (e: MouseEvent) => { if (!ref.current?.contains(e.target as Node)) setOpen(false); };
    const esc = (e: KeyboardEvent) => { if (e.key === 'Escape') setOpen(false); };
    document.addEventListener('mousedown', close);
    document.addEventListener('keydown', esc);
    return () => { document.removeEventListener('mousedown', close); document.removeEventListener('keydown', esc); };
  }, [open]);

  function signOut() {
    setSigningOut(true);
    // clears the local session, then WSO2 IS ends its session and returns to the home page (which asks for login)
    logout().catch(() => setSigningOut(false));
  }

  const rows: [string, string | undefined][] = [
    ['Username', user.username],
    ['Email', user.email],
    ['Phone', user.phone],
    ['Roles', user.roles.length ? user.roles.join(', ') : undefined],
  ];

  return (
    <div className="profile" ref={ref}>
      <button className="avatar" onClick={() => setOpen((o) => !o)} aria-haspopup="menu" aria-expanded={open} title={user.name}>
        {initials(user.name)}
      </button>
      {open && (
        <div className="profile-menu" role="menu">
          <div className="profile-head">
            <span className="avatar large">{initials(user.name)}</span>
            <div>
              <strong>{user.name}</strong>
              {user.email && <div className="muted">{user.email}</div>}
            </div>
          </div>
          <table><tbody>
            {rows.filter(([, v]) => v).map(([k, v]) => <tr key={k}><td className="muted">{k}</td><td>{v}</td></tr>)}
          </tbody></table>
          <button className="signout" onClick={signOut} disabled={signingOut}>{signingOut ? 'Signing out...' : 'Sign out'}</button>
        </div>
      )}
    </div>
  );
}

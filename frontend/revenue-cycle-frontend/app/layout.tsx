import './globals.css';
import AuthGate from '@/components/AuthGate';

export const metadata = { title: 'Billing - HIMS' };

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <AuthGate active="revenue-cycle">{children}</AuthGate>
      </body>
    </html>
  );
}

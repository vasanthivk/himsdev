import './globals.css';
import AuthGate from '@/components/AuthGate';

export const metadata = { title: 'HIMS - Dr Reddis HealthCare' };

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <AuthGate active="home">{children}</AuthGate>
      </body>
    </html>
  );
}

import './globals.css';
import AuthGate from '@/components/AuthGate';

export const metadata = { title: 'Patient Access - HIMS' };

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <AuthGate active="patient-engagement">{children}</AuthGate>
      </body>
    </html>
  );
}

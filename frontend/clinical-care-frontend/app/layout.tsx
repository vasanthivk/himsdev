import './globals.css';
import AuthGate from '@/components/AuthGate';

export const metadata = { title: 'Clinical Care - HIMS' };

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <AuthGate active="clinical-care">{children}</AuthGate>
      </body>
    </html>
  );
}

import './globals.css';
import AuthGate from '@/components/AuthGate';

export const metadata = { title: 'Laboratory - HIMS' };

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <AuthGate active="laboratory">{children}</AuthGate>
      </body>
    </html>
  );
}

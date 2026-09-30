import './globals.css';
import Nav from '@/components/Nav';

export const metadata = { title: 'Patient Access - HIMS' };

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <Nav active="patient-access" />
        <main>{children}</main>
      </body>
    </html>
  );
}

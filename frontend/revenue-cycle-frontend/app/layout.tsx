import './globals.css';
import Nav from '@/components/Nav';

export const metadata = { title: 'Billing - HIMS' };

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <Nav active="revenue-cycle" />
        <main>{children}</main>
      </body>
    </html>
  );
}

import './globals.css';
import Nav from '@/components/Nav';

export const metadata = { title: 'HIMS - Dr Reddis HealthCare' };

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <Nav active="home" />
        <main>{children}</main>
      </body>
    </html>
  );
}

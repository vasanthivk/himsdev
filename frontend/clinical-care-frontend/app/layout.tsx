import './globals.css';
import Nav from '@/components/Nav';

export const metadata = { title: 'Clinical Care - HIMS' };

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <Nav active="clinical-care" />
        <main>{children}</main>
      </body>
    </html>
  );
}

import './globals.css';
import Nav from '@/components/Nav';

export const metadata = { title: 'Laboratory - HIMS' };

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <Nav active="laboratory" />
        <main>{children}</main>
      </body>
    </html>
  );
}

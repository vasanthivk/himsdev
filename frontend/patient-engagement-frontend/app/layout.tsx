import './globals.css';
import AuthGate from '@/components/AuthGate';
import PatientAccessTabs from '@/components/PatientAccessTabs';

export const metadata = { title: 'Patient Access - HIMS' };

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <AuthGate active="patient-engagement"><PatientAccessTabs />{children}</AuthGate>
      </body>
    </html>
  );
}

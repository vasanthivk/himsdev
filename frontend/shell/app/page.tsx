'use client';
import { useEffect, useState } from 'react';
import { API, api, errMsg } from '@/lib/api';
import { Alert, Card } from '@/components/ui';

// The 7 microservices. With WSO2_AUTHENTICATION=true these are the gateway APIs, so each API must publish GET /health for its
// badge to turn green. Each URL is read when checked, so a missing one marks only that badge as down.
const services = [
  { name: 'Identity & Organization', base: () => API.identityOrg },
  { name: 'Patient Access & Engagement', base: () => API.patientEngagement },
  { name: 'Clinical Care', base: () => API.clinicalCare },
  { name: 'Diagnostics (Lab + Imaging)', base: () => API.diagnostics },
  { name: 'Revenue & Finance', base: () => API.revenueFinance },
  { name: 'Operations & Supply Chain', base: () => API.operationsSupply },
  { name: 'Integration & Communications', base: () => API.integrationComms },
];

const urlOf = (base: () => string) => { try { return base(); } catch { return 'not configured'; } };

const steps = [
  { n: 1, title: 'Add a device', href: '/diagnostics/analyzers', text: 'Laboratory registers the analyzer; the Integration Hub creates its channel in the Open Integration Engine.' },
  { n: 2, title: 'Register the patient', href: '/patient-engagement', text: 'UHID is generated; PatientRegistered is published.' },
  { n: 3, title: 'Start the OP visit and bill registration', href: '/patient-engagement/visit', text: 'Encounter with the doctor, then registration/consultation bill and payment.' },
  { n: 4, title: 'Doctor consultation', href: '/clinical-care', text: 'Complaint, SOAP note, diagnoses, prescription and lab orders.' },
  { n: 5, title: 'Bill the lab tests', href: '/revenue-finance', text: 'Revenue Cycle raised the lab bill from the OrderPlaced event; take the payment.' },
  { n: 6, title: 'Collect sample and run the test', href: '/diagnostics', text: 'Collect the barcoded sample; the device (or the simulator) sends the result.' },
  { n: 7, title: 'Result reaches the doctor and FHIR', href: '/clinical-care', text: 'Results are stored in the lab DB, the doctor sees them, and HAPI FHIR gets Observation + DiagnosticReport.' },
];

export default function Home() {
  const [health, setHealth] = useState<Record<string, string>>({});
  const [msg, setMsg] = useState<{ kind: 'ok' | 'error'; text: string } | null>(null);
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    const check = async () => {
      const out: Record<string, string> = {};
      await Promise.all(services.map(async (s) => {
        try { const h = await api(s.base(), '/health'); out[s.name] = h.status; } catch { out[s.name] = 'down'; }
      }));
      setHealth(out);
    };
    check();
    const t = setInterval(check, 10000);
    return () => clearInterval(t);
  }, []);

  async function loadReferenceData() {
    setBusy(true); setMsg(null);
    try {
      const a = await api(API.identityOrg, '/api/admin/republish', { method: 'POST' });
      const b = await api(API.revenueFinance, '/api/admin/republish', { method: 'POST' });
      setMsg({ kind: 'ok', text: `Published ${a.organizations} organization(s), ${a.branches} branch(es), ${a.departments} department(s), ${a.practitioners} practitioner(s) and ${b.services} service(s). Other services fill their ref tables from these events within a few seconds.` });
    } catch (e) { setMsg({ kind: 'error', text: errMsg(e) }); }
    setBusy(false);
  }

  return (
    <>
      <h1>Hospital Information Management System</h1>
      <div className="split">
        <Card title="Service health">
          <table><tbody>
            {services.map((s) => (
              <tr key={s.name}><td>{s.name}</td><td className="muted">{urlOf(s.base)}</td>
                <td><span className={`badge ${health[s.name] === 'healthy' ? 'green' : health[s.name] === 'degraded' ? 'amber' : 'red'}`}>{health[s.name] ?? '...'}</span></td></tr>
            ))}
          </tbody></table>
        </Card>
        <Card title="First run: load reference data">
          <p className="muted">Branches, practitioners and the service catalogue are owned by Identity & Organization and Revenue & Finance. This publishes them as events so Patient Access &amp; Engagement, Clinical Care and Diagnostics can fill their <code>ref.*</code> tables. Safe to repeat.</p>
          <button onClick={loadReferenceData} disabled={busy}>{busy ? 'Publishing...' : 'Load reference data'}</button>
          {msg && <Alert kind={msg.kind}>{msg.text}</Alert>}
        </Card>
      </div>
      <Card title="The workflow">
        <table><tbody>
          {steps.map((s) => (
            <tr key={s.n}><td style={{ width: 28 }}><strong>{s.n}</strong></td><td style={{ width: 300 }}><a href={s.href}>{s.title}</a></td><td className="muted">{s.text}</td></tr>
          ))}
        </tbody></table>
      </Card>
    </>
  );
}

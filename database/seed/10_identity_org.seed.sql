-- Minimal reference data for the workflow. Safe to re-run. Owned by Identity, Organization & Reference Data.
INSERT INTO core.organization (org_code, org_name, legal_name)
VALUES ('DRR', 'Dr Reddis HealthCare', 'Dr Reddis HealthCare Private Limited') ON CONFLICT (org_code) DO NOTHING;

INSERT INTO core.branch (organization_id, branch_code, branch_name, branch_type, city, state_code, gstin)
SELECT o.organization_id, 'HYD01', 'Dr Reddis Hospital - Hyderabad', 'HOSPITAL', 'Hyderabad', 'TS', NULL
  FROM core.organization o WHERE o.org_code = 'DRR' ON CONFLICT (branch_code) DO NOTHING;

INSERT INTO mst.department (organization_id, dept_code, dept_name, dept_type)
SELECT o.organization_id, d.code, d.name, d.typ FROM core.organization o,
  (VALUES ('GENMED','General Medicine','CLINICAL'), ('LAB','Clinical Laboratory','DIAGNOSTIC'), ('FRONT','Front Office','ADMIN')) AS d(code,name,typ)
 WHERE o.org_code = 'DRR' ON CONFLICT (organization_id, dept_code) DO NOTHING;

INSERT INTO mst.specialty (specialty_code, specialty_name, department_id)
SELECT 'GENMED', 'General Medicine', d.department_id FROM mst.department d WHERE d.dept_code = 'GENMED' ON CONFLICT (specialty_code) DO NOTHING;

INSERT INTO hr.employee (organization_id, branch_id, employee_code, title, first_name, last_name, gender, department_id, employment_type)
SELECT o.organization_id, b.branch_id, e.code, e.title, e.fn, e.ln, e.g, d.department_id, 'PERMANENT'
  FROM core.organization o
  JOIN core.branch b ON b.organization_id = o.organization_id AND b.branch_code = 'HYD01'
  JOIN (VALUES ('E0001','Dr','Anil','Reddy','male','GENMED'), ('E0002','Dr','Sunita','Rao','female','GENMED')) AS e(code,title,fn,ln,g,dept) ON TRUE
  JOIN mst.department d ON d.organization_id = o.organization_id AND d.dept_code = e.dept
 WHERE o.org_code = 'DRR' ON CONFLICT (employee_code) DO NOTHING;

INSERT INTO hr.practitioner (organization_id, employee_id, practitioner_type, display_name, primary_specialty_id, qualification, registration_no, default_consult_fee)
SELECT e.organization_id, e.employee_id, 'INHOUSE', e.title || ' ' || e.first_name || ' ' || e.last_name,
       (SELECT specialty_id FROM mst.specialty WHERE specialty_code = 'GENMED'), 'MBBS, MD', 'TSMC-' || e.employee_code, 500
  FROM hr.employee e
 WHERE e.employee_code IN ('E0001','E0002')
   AND NOT EXISTS (SELECT 1 FROM hr.practitioner p WHERE p.employee_id = e.employee_id);

-- Dr Reddis HealthCare (DRR) reference data. Safe to re-run. Owned by Identity, Organization & Reference Data.
-- Run inside this tenant's own database (created outside these scripts), after full/ and roles.sql:
--   psql -d <tenant_database> -v ON_ERROR_STOP=1 -f 01_identityorg.seed.sql   (then 06_revenuefinance, then 04_lims)

-- The tenant itself: one row per database (organisation profile for reports and letterheads).
INSERT INTO identityorg.core_organization (org_code, org_name, legal_name)
VALUES ('DRR', 'Dr Reddis HealthCare', 'Dr Reddis HealthCare Private Limited') ON CONFLICT (org_code) DO NOTHING;

INSERT INTO identityorg.core_branch (branch_code, branch_name, branch_type, city, state_code, gstin)
VALUES ('HYD01', 'Dr Reddis Hospital - Hyderabad', 'HOSPITAL', 'Hyderabad', 'TS', NULL) ON CONFLICT (branch_code) DO NOTHING;

INSERT INTO identityorg.mst_core_department (dept_code, dept_name, dept_type) VALUES
  ('GENMED','General Medicine','CLINICAL'), ('LAB','Clinical Laboratory','DIAGNOSTIC'), ('FRONT','Front Office','ADMIN')
ON CONFLICT (dept_code) DO NOTHING;

INSERT INTO identityorg.mst_hr_specialty (specialty_code, specialty_name, department_id)
SELECT 'GENMED', 'General Medicine', d.department_id FROM identityorg.mst_core_department d
 WHERE d.dept_code = 'GENMED' ON CONFLICT (specialty_code) DO NOTHING;

INSERT INTO identityorg.hr_employee (branch_id, employee_code, title, first_name, last_name, gender, department_id, employment_type)
SELECT b.branch_id, e.code, e.title, e.fn, e.ln, e.g, d.department_id, 'PERMANENT'
  FROM identityorg.core_branch b
  JOIN (VALUES ('E0001','Dr','Anil','Reddy','male','GENMED'),
       ('E0002','Dr','Sunita','Rao','female','GENMED')) AS e(code,title,fn,ln,g,dept) ON TRUE
  JOIN identityorg.mst_core_department d ON d.dept_code = e.dept
 WHERE b.branch_code = 'HYD01' ON CONFLICT (employee_code) DO NOTHING;

INSERT INTO identityorg.hr_practitioner (employee_id, practitioner_type, display_name, primary_specialty_id, qualification, registration_no, default_consult_fee)
SELECT e.employee_id, 'INHOUSE', e.title || ' ' || e.first_name || ' ' || e.last_name,
       (SELECT specialty_id FROM identityorg.mst_hr_specialty WHERE specialty_code = 'GENMED'), 'MBBS, MD', 'TSMC-' || e.employee_code, 500
  FROM identityorg.hr_employee e
 WHERE e.employee_code IN ('E0001', 'E0002')
   AND NOT EXISTS (SELECT 1 FROM identityorg.hr_practitioner p WHERE p.employee_id = e.employee_id);

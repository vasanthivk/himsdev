-- Apollo (organization 2) reference data for the workflow, in Apollo's own database hims_apollo. Safe to re-run.
-- Run against hims_apollo only:  psql -d hims_apollo -v ON_ERROR_STOP=1 -f apollo.seed.sql
-- Afterwards press "Load reference data" on https://apollo.localhost:3000 so the other services receive the doctor and the
-- service catalogue (PractitionerUpdated, ServiceUpdated on hims.apollo.events).

-- Doctor: Dr Priya Sharma, General Medicine, Apollo Hospital (APL01).
INSERT INTO identity_org.mst_specialty (specialty_code, specialty_name, department_id)
SELECT 'GENMED', 'General Medicine', d.department_id FROM identity_org.mst_department d
 WHERE d.organization_id = 2 AND d.dept_code = 'GENMED' ON CONFLICT (specialty_code) DO NOTHING;

INSERT INTO identity_org.hr_employee (organization_id, branch_id, employee_code, title, first_name, last_name, gender, department_id, employment_type)
SELECT 2, b.branch_id, 'APL-E0001', 'Dr', 'Priya', 'Sharma', 'female', d.department_id, 'PERMANENT'
  FROM identity_org.core_branch b JOIN identity_org.mst_department d ON d.organization_id = 2 AND d.dept_code = 'GENMED'
 WHERE b.branch_code = 'APL01' ON CONFLICT (employee_code) DO NOTHING;

INSERT INTO identity_org.hr_practitioner (organization_id, employee_id, practitioner_type, display_name, primary_specialty_id, qualification, registration_no, default_consult_fee)
SELECT e.organization_id, e.employee_id, 'INHOUSE', 'Dr Priya Sharma',
       (SELECT specialty_id FROM identity_org.mst_specialty WHERE specialty_code = 'GENMED'), 'MBBS, MD', 'TSMC-APL-E0001', 500
  FROM identity_org.hr_employee e
 WHERE e.employee_code = 'APL-E0001'
   AND NOT EXISTS (SELECT 1 FROM identity_org.hr_practitioner p WHERE p.employee_id = e.employee_id);

-- Service catalogue (same ids as Reddy's, so diagnostics.mst_lab_test.service_id lines up) and the self-pay OPD tariff.
INSERT INTO revenue_finance.mst_service (service_id, organization_id, service_category_id, service_code, service_name, service_type, gst_rate, is_orderable, is_billable)
SELECT s.id, 2, c.service_category_id, s.code, s.name, s.typ, 0, s.orderable, TRUE
  FROM (VALUES
    (1,   'REG-FEE',   'OP Registration Fee',                 'MISC',         'REGISTRATION', FALSE),
    (2,   'CONS-GM',   'Consultation - General Medicine',      'CONSULTATION', 'CONSULTATION', FALSE),
    (101, 'LAB-CBC',   'Complete Blood Count (CBC)',           'LAB_TEST',     'LABORATORY',   TRUE),
    (102, 'LAB-FBS',   'Fasting Blood Sugar',                  'LAB_TEST',     'LABORATORY',   TRUE),
    (103, 'LAB-LIPID', 'Lipid Profile',                        'LAB_TEST',     'LABORATORY',   TRUE),
    (104, 'LAB-HBA1C', 'HbA1c (Glycated Haemoglobin)',         'LAB_TEST',     'LABORATORY',   TRUE)
  ) AS s(id, code, name, typ, cat, orderable)
  JOIN revenue_finance.mst_service_category c ON c.category_code = s.cat
ON CONFLICT (organization_id, service_code) DO NOTHING;
SELECT setval(pg_get_serial_sequence('revenue_finance.mst_service', 'service_id'), GREATEST((SELECT max(service_id) FROM revenue_finance.mst_service), 1));

INSERT INTO revenue_finance.mst_tariff_plan (organization_id, plan_code, plan_name, plan_type, valid_from)
SELECT 2, 'GEN-OPD', 'General OPD Tariff (Self pay)', 'GENERAL', DATE '2020-01-01'
 WHERE NOT EXISTS (SELECT 1 FROM revenue_finance.mst_tariff_plan WHERE organization_id = 2 AND plan_code = 'GEN-OPD');

INSERT INTO revenue_finance.mst_tariff_rate (tariff_plan_id, service_id, rate, valid_from)
SELECT p.tariff_plan_id, r.sid, r.rate, DATE '2020-01-01'
  FROM revenue_finance.mst_tariff_plan p, (VALUES (1, 200.00), (2, 500.00), (101, 350.00), (102, 100.00), (103, 600.00), (104, 450.00)) AS r(sid, rate)
 WHERE p.organization_id = 2 AND p.plan_code = 'GEN-OPD'
   AND NOT EXISTS (SELECT 1 FROM revenue_finance.mst_tariff_rate t WHERE t.tariff_plan_id = p.tariff_plan_id AND t.service_id = r.sid);

-- Lab tests and their parameters (LOINC codes), owned by Laboratory.
INSERT INTO diagnostics.mst_lab_test (service_id, lab_section, specimen_type, container_type, is_panel, tat_minutes) VALUES
  (101, 'HEMATOLOGY',   'BLOOD', 'EDTA',  TRUE,  120),
  (102, 'BIOCHEMISTRY', 'BLOOD', 'FLUORIDE', FALSE, 90),
  (103, 'BIOCHEMISTRY', 'BLOOD', 'SST',   TRUE,  180),
  (104, 'BIOCHEMISTRY', 'BLOOD', 'EDTA',  FALSE, 240)
ON CONFLICT (service_id) DO NOTHING;

INSERT INTO diagnostics.mst_lab_parameter (lab_test_id, parameter_code, parameter_name, result_type, unit, decimal_places, display_order)
SELECT t.lab_test_id, p.code, p.name, 'NUMERIC', p.unit, p.dp, p.ord
  FROM diagnostics.mst_lab_test t
  JOIN (VALUES
    (101,'6690-2','WBC (Total Leucocyte Count)','10*3/uL',1,1), (101,'789-8','RBC Count','10*6/uL',2,2),
    (101,'718-7','Haemoglobin','g/dL',1,3),                     (101,'4544-3','Haematocrit (PCV)','%',1,4),
    (101,'777-3','Platelet Count','10*3/uL',0,5),
    (102,'1558-6','Fasting Glucose','mg/dL',0,1),
    (103,'2093-3','Total Cholesterol','mg/dL',0,1), (103,'2085-9','HDL Cholesterol','mg/dL',0,2),
    (103,'13457-7','LDL Cholesterol (calculated)','mg/dL',0,3), (103,'2571-8','Triglycerides','mg/dL',0,4),
    (104,'4548-4','HbA1c','%',1,1)
  ) AS p(sid, code, name, unit, dp, ord) ON p.sid = t.service_id
 WHERE NOT EXISTS (SELECT 1 FROM diagnostics.mst_lab_parameter x WHERE x.lab_test_id = t.lab_test_id AND x.parameter_code = p.code);

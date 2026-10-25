-- Service catalogue + a default self-pay tariff for the workflow. Safe to re-run. Owned by Revenue Cycle.
-- Explicit service ids are used so Laboratory's mst.lab_test.service_id (a logical FK) lines up.
INSERT INTO mst.service_category (category_code, category_name) VALUES
  ('REGISTRATION','Registration'), ('CONSULTATION','Consultation'), ('LABORATORY','Laboratory')
ON CONFLICT (category_code) DO NOTHING;

INSERT INTO mst.service (service_id, organization_id, service_category_id, service_code, service_name, service_type, gst_rate, is_orderable, is_billable)
SELECT s.id, 1, c.service_category_id, s.code, s.name, s.typ, 0, s.orderable, TRUE
  FROM (VALUES
    (1,   'REG-FEE',   'OP Registration Fee',                 'MISC',         'REGISTRATION', FALSE),
    (2,   'CONS-GM',   'Consultation - General Medicine',      'CONSULTATION', 'CONSULTATION', FALSE),
    (101, 'LAB-CBC',   'Complete Blood Count (CBC)',           'LAB_TEST',     'LABORATORY',   TRUE),
    (102, 'LAB-FBS',   'Fasting Blood Sugar',                  'LAB_TEST',     'LABORATORY',   TRUE),
    (103, 'LAB-LIPID', 'Lipid Profile',                        'LAB_TEST',     'LABORATORY',   TRUE),
    (104, 'LAB-HBA1C', 'HbA1c (Glycated Haemoglobin)',         'LAB_TEST',     'LABORATORY',   TRUE)
  ) AS s(id, code, name, typ, cat, orderable)
  JOIN mst.service_category c ON c.category_code = s.cat
ON CONFLICT (organization_id, service_code) DO NOTHING;
SELECT setval(pg_get_serial_sequence('mst.service', 'service_id'), GREATEST((SELECT max(service_id) FROM mst.service), 1));

INSERT INTO mst.tariff_plan (organization_id, plan_code, plan_name, plan_type, valid_from)
SELECT 1, 'GEN-OPD', 'General OPD Tariff (Self pay)', 'GENERAL', DATE '2020-01-01'
 WHERE NOT EXISTS (SELECT 1 FROM mst.tariff_plan WHERE plan_code = 'GEN-OPD');

INSERT INTO mst.tariff_rate (tariff_plan_id, service_id, rate, valid_from)
SELECT p.tariff_plan_id, r.sid, r.rate, DATE '2020-01-01'
  FROM mst.tariff_plan p, (VALUES (1, 200.00), (2, 500.00), (101, 350.00), (102, 100.00), (103, 600.00), (104, 450.00)) AS r(sid, rate)
 WHERE p.plan_code = 'GEN-OPD'
   AND NOT EXISTS (SELECT 1 FROM mst.tariff_rate t WHERE t.tariff_plan_id = p.tariff_plan_id AND t.service_id = r.sid);

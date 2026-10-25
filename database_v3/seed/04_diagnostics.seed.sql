-- Lab test master for the workflow. Safe to re-run. Owned by Laboratory.
-- service_id values match the Revenue Cycle seed (logical FK -> revenue_finance.mst_service [Revenue Cycle]).
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

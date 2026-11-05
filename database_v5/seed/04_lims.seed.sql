-- Lab masters for the workflow. Safe to re-run. Owned by LIMS.
-- service_id values match the Revenue Cycle seed (logical FK -> revenuefinance.mst_bil_service [Revenue Cycle]).
INSERT INTO lims.mst_lab_section (section_code, section_name) VALUES
  ('HEMATOLOGY', 'Haematology'),
  ('BIOCHEMISTRY', 'Biochemistry'),
  ('ENDOCRINOLOGY', 'Endocrinology'),
  ('IMMUNOLOGY', 'Immunology'),
  ('TOXICOLOGY', 'Toxicology'),
  ('SEROLOGY', 'Serology / Virology'),
  ('MICROBIOLOGY', 'Microbiology'),
  ('PATHOLOGY', 'Pathology'),
  ('HISTOPATHOLOGY', 'Histopathology'),
  ('GENETICS', 'Genetics'),
  ('BONE_MARROW', 'Bone Marrow'),
  ('BLOOD_BANK', 'Blood Bank')
ON CONFLICT (section_code) DO NOTHING;

INSERT INTO lims.mst_lab_specimen_type (specimen_code, specimen_name) VALUES
  ('BLOOD', 'Whole blood'), ('SERUM', 'Serum'), ('PLASMA', 'Plasma'), ('URINE', 'Urine'),
  ('STOOL', 'Stool'), ('CSF', 'Cerebrospinal fluid'), ('TISSUE', 'Tissue'), ('SWAB', 'Swab')
ON CONFLICT (specimen_code) DO NOTHING;

INSERT INTO lims.mst_lab_container (container_code, container_name, cap_colour, additive) VALUES
  ('EDTA', 'EDTA tube', 'Lavender', 'EDTA'), ('SST', 'Serum separator tube', 'Gold', 'SST'),
  ('FLUORIDE', 'Fluoride tube', 'Grey', 'FLUORIDE'), ('CITRATE', 'Citrate tube', 'Light blue', 'CITRATE'),
  ('PLAIN', 'Plain tube', 'Red', 'PLAIN')
ON CONFLICT (container_code) DO NOTHING;

INSERT INTO lims.mst_lab_test (service_id, lab_section_id, specimen_type_id, container_type_id, is_panel, tat_minutes)
SELECT v.service_id, ls.lab_section_id, s.lab_specimen_type_id, c.lab_container_id, v.is_panel, v.tat_minutes
  FROM (VALUES
    (101, 'HEMATOLOGY',   'BLOOD', 'EDTA',     TRUE,  120),
    (102, 'BIOCHEMISTRY', 'BLOOD', 'FLUORIDE', FALSE, 90),
    (103, 'BIOCHEMISTRY', 'BLOOD', 'SST',      TRUE,  180),
    (104, 'BIOCHEMISTRY', 'BLOOD', 'EDTA',     FALSE, 240)
  ) AS v(service_id, section_code, specimen_code, container_code, is_panel, tat_minutes)
  JOIN lims.mst_lab_section ls ON ls.section_code = v.section_code
  JOIN lims.mst_lab_specimen_type s ON s.specimen_code = v.specimen_code
  LEFT JOIN lims.mst_lab_container c ON c.container_code = v.container_code
ON CONFLICT (service_id) DO NOTHING;

INSERT INTO lims.mst_lab_parameter (lab_test_id, parameter_code, parameter_name, result_type, unit, decimal_places, display_order)
SELECT t.lab_test_id, p.code, p.name, 'NUMERIC', p.unit, p.dp, p.ord
  FROM lims.mst_lab_test t
  JOIN (VALUES
    (101,'6690-2','WBC (Total Leucocyte Count)','10*3/uL',1,1), (101,'789-8','RBC Count','10*6/uL',2,2),
    (101,'718-7','Haemoglobin','g/dL',1,3),                     (101,'4544-3','Haematocrit (PCV)','%',1,4),
    (101,'777-3','Platelet Count','10*3/uL',0,5),
    (102,'1558-6','Fasting Glucose','mg/dL',0,1),
    (103,'2093-3','Total Cholesterol','mg/dL',0,1), (103,'2085-9','HDL Cholesterol','mg/dL',0,2),
    (103,'13457-7','LDL Cholesterol (calculated)','mg/dL',0,3), (103,'2571-8','Triglycerides','mg/dL',0,4),
    (104,'4548-4','HbA1c','%',1,1)
  ) AS p(sid, code, name, unit, dp, ord) ON p.sid = t.service_id
 WHERE NOT EXISTS (SELECT 1 FROM lims.mst_lab_parameter x WHERE x.lab_test_id = t.lab_test_id AND x.parameter_code = p.code);

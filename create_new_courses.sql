INSERT INTO course (code, name, description, academic_year, class_group)
VALUES
  ('2627-DSGAI-2-45810-A', 'Google Cloud Digital Leader',
   'Curso GCDL 2627, grupo A inglés', 2627, 'A'),
  ('2627-ADN-3-6033-A', 'Visualization and Reporting',
   'Curso de visualización y reporting, grupo ADN-A inglés', 2627, 'A'),
  ('2627-ADN-3-6033-AIB1', 'Visualization and Reporting',
   'Curso de visualización y reporting, grupo ADN-AIB1 inglés', 2627, 'AIB1')
RETURNING id, code, name;
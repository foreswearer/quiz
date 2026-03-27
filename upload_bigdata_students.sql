-- Upload students for Big Data III: Visualization (2526-ANBA-3-5354-A)
-- Safe to run multiple times (idempotent)

DO $$
DECLARE
    v_course_id BIGINT;
    v_user_id   BIGINT;
BEGIN
    SELECT id INTO v_course_id FROM course WHERE code = '2526-ANBA-3-5354-A';
    IF v_course_id IS NULL THEN
        RAISE EXCEPTION 'Course 2526-ANBA-3-5354-A not found';
    END IF;
    RAISE NOTICE 'Found course id=%', v_course_id;

    -- Insert students and enroll them
    WITH students (dni, full_name) AS (
        VALUES
        ('78276121', 'Javier Aguilar Martínez'),
        ('54296922', 'Hugo Alonso Mediano'),
        ('51531757', 'Javier Álvarez González'),
        ('44924194', 'Inés Baptista de Carvalho Martínez-Falero'),
        ('06661902', 'Lorenzo Cadenas Gómez'),
        ('05953276', 'Javier Cano Lahoz'),
        ('54492516', 'Javier Chozas Toledo'),
        ('53938901', 'Antonio de Frutos Castelo'),
        ('52903378', 'Mateo Fernández Infante'),
        ('04849849', 'Sergio Fernández Shandrovych'),
        ('03203790', 'Rubén Garzón Cortijo'),
        ('51124252', 'Daniel Guilabert Borreguero'),
        ('51526977', 'Enrique Isasi Pita'),
        ('51124626', 'David Jesús Martín Luna'),
        ('51112455', 'Ramzi Masri Kayali'),
        ('54720055', 'Miguel Mercadé de Lucas'),
        ('53936509', 'Gonzalo Nocea Beneytez'),
        ('53811927', 'Iñigo Pons Mateo'),
        ('50354697', 'Alberto Rojas Martínez'),
        ('48200082', 'Andrés Rosas Saldaña'),
        ('Z0854328', 'Sergio Andrés Sandoval Llanos'),
        ('53937922', 'Gonzalo Valverde Morales'),
        ('38884181', 'Pol Batiste Antón'),
        ('DJF623158', 'Faustyna Szala'),
        ('51742869', 'Gonzalo Arranz Sánchez'),
        ('05956235', 'Celia Cogollos Bustamante'),
        ('47299389', 'Alejandro Cue Biryukov'),
        ('02778470', 'Javier Durán Gómez'),
        ('54366319', 'Diego Frutos Rojas'),
        ('04850824', 'Marcos García Balboa'),
        ('71208728', 'Javier González Marcos'),
        ('54444105', 'Alejandro González Salces'),
        ('60136630', 'Dayana Micaela López Acevedo'),
        ('51511280', 'Marta López-Manzanares Pérez'),
        ('02774223', 'Pablo Obreo Cordero'),
        ('47475179', 'Daniel Padilla de Loro'),
        ('05952302', 'Gonzalo Pintor Novo'),
        ('72325443', 'Santiago Andrés Ramallo Chacón'),
        ('54700910', 'Marcos Rodríguez Romero')
    ),
    inserted AS (
        INSERT INTO app_user (dni, email, full_name, role, is_active)
        SELECT
            dni,
            dni || '@2526-anba-3-5354-a.local',
            full_name,
            'student',
            true
        FROM students
        ON CONFLICT (dni) DO NOTHING
        RETURNING id, dni
    ),
    all_users AS (
        SELECT id, dni FROM inserted
        UNION ALL
        SELECT u.id, u.dni FROM app_user u
        JOIN students s ON s.dni = u.dni
        WHERE u.dni NOT IN (SELECT dni FROM inserted)
    )
    INSERT INTO course_enrollment (course_id, user_id, role_in_course)
    SELECT v_course_id, id, 'student'
    FROM all_users
    WHERE NOT EXISTS (
        SELECT 1 FROM course_enrollment ce
        WHERE ce.course_id = v_course_id AND ce.user_id = all_users.id
    );

    RAISE NOTICE 'Done.';
END;
$$;

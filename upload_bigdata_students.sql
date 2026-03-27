-- Upload students for Big Data III: Visualization (2526-ANBA-3-5354-A)
-- Safe to run multiple times (idempotent)

DO $$
DECLARE
    v_course_id BIGINT;
    v_user_id   BIGINT;
    v_dni       TEXT;
    v_name      TEXT;
    students    TEXT[][] := ARRAY[
        ARRAY['78276121', 'Javier Aguilar Martínez'],
        ARRAY['54296922', 'Hugo Alonso Mediano'],
        ARRAY['51531757', 'Javier Álvarez González'],
        ARRAY['44924194', 'Inés Baptista de Carvalho Martínez-Falero'],
        ARRAY['06661902', 'Lorenzo Cadenas Gómez'],
        ARRAY['05953276', 'Javier Cano Lahoz'],
        ARRAY['54492516', 'Javier Chozas Toledo'],
        ARRAY['53938901', 'Antonio de Frutos Castelo'],
        ARRAY['52903378', 'Mateo Fernández Infante'],
        ARRAY['04849849', 'Sergio Fernández Shandrovych'],
        ARRAY['03203790', 'Rubén Garzón Cortijo'],
        ARRAY['51124252', 'Daniel Guilabert Borreguero'],
        ARRAY['51526977', 'Enrique Isasi Pita'],
        ARRAY['51124626', 'David Jesús Martín Luna'],
        ARRAY['51112455', 'Ramzi Masri Kayali'],
        ARRAY['54720055', 'Miguel Mercadé de Lucas'],
        ARRAY['53936509', 'Gonzalo Nocea Beneytez'],
        ARRAY['53811927', 'Iñigo Pons Mateo'],
        ARRAY['50354697', 'Alberto Rojas Martínez'],
        ARRAY['48200082', 'Andrés Rosas Saldaña'],
        ARRAY['Z0854328', 'Sergio Andrés Sandoval Llanos'],
        ARRAY['53937922', 'Gonzalo Valverde Morales'],
        ARRAY['38884181', 'Pol Batiste Antón'],
        ARRAY['DJF623158', 'Faustyna Szala'],
        ARRAY['51742869', 'Gonzalo Arranz Sánchez'],
        ARRAY['05956235', 'Celia Cogollos Bustamante'],
        ARRAY['47299389', 'Alejandro Cue Biryukov'],
        ARRAY['02778470', 'Javier Durán Gómez'],
        ARRAY['54366319', 'Diego Frutos Rojas'],
        ARRAY['04850824', 'Marcos García Balboa'],
        ARRAY['71208728', 'Javier González Marcos'],
        ARRAY['54444105', 'Alejandro González Salces'],
        ARRAY['60136630', 'Dayana Micaela López Acevedo'],
        ARRAY['51511280', 'Marta López-Manzanares Pérez'],
        ARRAY['02774223', 'Pablo Obreo Cordero'],
        ARRAY['47475179', 'Daniel Padilla de Loro'],
        ARRAY['05952302', 'Gonzalo Pintor Novo'],
        ARRAY['72325443', 'Santiago Andrés Ramallo Chacón'],
        ARRAY['54700910', 'Marcos Rodríguez Romero']
    ];
BEGIN
    SELECT id INTO v_course_id FROM course WHERE code = '2526-ANBA-3-5354-A';
    IF v_course_id IS NULL THEN
        RAISE EXCEPTION 'Course 2526-ANBA-3-5354-A not found';
    END IF;
    RAISE NOTICE 'Found course id=%', v_course_id;

    FOR i IN 1 .. array_length(students, 1) LOOP
        v_dni  := students[i][1];
        v_name := students[i][2];

        SELECT id INTO v_user_id FROM app_user WHERE dni = v_dni;
        IF v_user_id IS NULL THEN
            INSERT INTO app_user (dni, email, full_name, role, is_active)
            VALUES (v_dni, v_dni || '@2526-anba-3-5354-a.local', v_name, 'student', true)
            RETURNING id INTO v_user_id;
            RAISE NOTICE 'Created user: % (%)', v_name, v_dni;
        ELSE
            RAISE NOTICE 'User already exists: % (%)', v_name, v_dni;
        END IF;

        IF NOT EXISTS (
            SELECT 1 FROM course_enrollment
            WHERE course_id = v_course_id AND user_id = v_user_id
        ) THEN
            INSERT INTO course_enrollment (course_id, user_id, role_in_course)
            VALUES (v_course_id, v_user_id, 'student');
        END IF;
    END LOOP;

    RAISE NOTICE 'Done.';
END;
$$;

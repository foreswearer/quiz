"""
Upload students for course "BigData III: Visualization".

This script is idempotent:
- Creates the course if it does not already exist (looked up by name).
- Inserts students into app_user if they don't already exist (keyed on DNI).
- Enrolls each student in the course if not already enrolled.
"""

import sys
import os

sys.path.append(os.getcwd())

from app.db import get_connection  # noqa: E402

COURSE_NAME = "BigData III: Visualization"
COURSE_CODE = "2526-BIGDATA3-A"
COURSE_DESCRIPTION = "BigData III: Visualization, grupo A"
ACADEMIC_YEAR = 2526
CLASS_GROUP = "A"

# (dni, full_name) — name converted from "Last, First" to "First Last"
STUDENTS = [
    ("78276121", "Javier Aguilar Martínez"),
    ("54296922", "Hugo Alonso Mediano"),
    ("51531757", "Javier Álvarez González"),
    ("44924194", "Inés Baptista de Carvalho Martínez-Falero"),
    ("06661902", "Lorenzo Cadenas Gómez"),
    ("05953276", "Javier Cano Lahoz"),
    ("54492516", "Javier Chozas Toledo"),
    ("53938901", "Antonio de Frutos Castelo"),
    ("52903378", "Mateo Fernández Infante"),
    ("04849849", "Sergio Fernández Shandrovych"),
    ("03203790", "Rubén Garzón Cortijo"),
    ("51124252", "Daniel Guilabert Borreguero"),
    ("51526977", "Enrique Isasi Pita"),
    ("51124626", "David Jesús Martín Luna"),
    ("51112455", "Ramzi Masri Kayali"),
    ("54720055", "Miguel Mercadé de Lucas"),
    ("53936509", "Gonzalo Nocea Beneytez"),
    ("53811927", "Iñigo Pons Mateo"),
    ("50354697", "Alberto Rojas Martínez"),
    ("48200082", "Andrés Rosas Saldaña"),
    ("Z0854328", "Sergio Andrés Sandoval Llanos"),
    ("53937922", "Gonzalo Valverde Morales"),
    ("38884181", "Pol Batiste Antón"),
    ("DJF623158", "Faustyna Szala"),
    ("51742869", "Gonzalo Arranz Sánchez"),
    ("05956235", "Celia Cogollos Bustamante"),
    ("47299389", "Alejandro Cue Biryukov"),
    ("02778470", "Javier Durán Gómez"),
    ("54366319", "Diego Frutos Rojas"),
    ("04850824", "Marcos García Balboa"),
    ("71208728", "Javier González Marcos"),
    ("54444105", "Alejandro González Salces"),
    ("60136630", "Dayana Micaela López Acevedo"),
    ("51511280", "Marta López-Manzanares Pérez"),
    ("02774223", "Pablo Obreo Cordero"),
    ("47475179", "Daniel Padilla de Loro"),
    ("05952302", "Gonzalo Pintor Novo"),
    ("72325443", "Santiago Andrés Ramallo Chacón"),
    ("54700910", "Marcos Rodríguez Romero"),
]


def get_or_create_course(cur):
    cur.execute("SELECT id FROM course WHERE name = %s", (COURSE_NAME,))
    row = cur.fetchone()
    if row:
        course_id = row[0]
        print(f"Course already exists with id={course_id}")
        return course_id

    # Find a teacher to use as owner (id=1 is the default teacher)
    cur.execute("SELECT id FROM app_user WHERE role = 'teacher' LIMIT 1")
    teacher_row = cur.fetchone()
    owner_id = teacher_row[0] if teacher_row else None

    cur.execute(
        """
        INSERT INTO course (code, name, description, owner_id, academic_year, class_group, is_active)
        VALUES (%s, %s, %s, %s, %s, %s, true)
        RETURNING id
        """,
        (COURSE_CODE, COURSE_NAME, COURSE_DESCRIPTION, owner_id, ACADEMIC_YEAR, CLASS_GROUP),
    )
    course_id = cur.fetchone()[0]
    print(f"Created course '{COURSE_NAME}' with id={course_id}")
    return course_id


def upsert_student(cur, dni, full_name, course_code):
    email = f"{dni}@{course_code.lower()}.local"
    cur.execute(
        """
        INSERT INTO app_user (dni, email, full_name, role, is_active)
        VALUES (%s, %s, %s, 'student', true)
        ON CONFLICT (dni) DO NOTHING
        RETURNING id
        """,
        (dni, email, full_name),
    )
    row = cur.fetchone()
    if row:
        return row[0], True  # (id, created)

    cur.execute("SELECT id FROM app_user WHERE dni = %s", (dni,))
    return cur.fetchone()[0], False


def enroll_student(cur, course_id, user_id):
    cur.execute(
        """
        INSERT INTO course_enrollment (course_id, user_id, role_in_course)
        VALUES (%s, %s, 'student')
        ON CONFLICT DO NOTHING
        """,
        (course_id, user_id),
    )
    return cur.rowcount > 0


def main():
    print(f"Starting upload for course: {COURSE_NAME}")
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            course_id = get_or_create_course(cur)

            created_count = 0
            enrolled_count = 0

            for dni, full_name in STUDENTS:
                user_id, was_created = upsert_student(cur, dni, full_name, COURSE_CODE)
                if was_created:
                    created_count += 1
                    print(f"  Created student: {full_name} ({dni})")
                else:
                    print(f"  Student already exists: {full_name} ({dni})")

                newly_enrolled = enroll_student(cur, course_id, user_id)
                if newly_enrolled:
                    enrolled_count += 1

        conn.commit()
        print(
            f"\nDone! {created_count} new student(s) created, "
            f"{enrolled_count} new enrollment(s) added."
        )
    except Exception as e:
        print(f"Error: {e}")
        conn.rollback()
        sys.exit(1)
    finally:
        conn.close()


if __name__ == "__main__":
    main()

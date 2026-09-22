"""
Upload 2026/27 students and enrol them in their courses.

Idempotent: existing users are matched by DNI and left untouched;
enrolments rely on the unique index uq_course_enrollment_course_user.
Courses must already exist — the script refuses to invent them.

Usage:  python upload_students_2627.py [--dry-run]
"""

import os
import sys

sys.path.append(os.getcwd())

from app.db import get_connection  # noqa: E402

DRY_RUN = "--dry-run" in sys.argv

# course_code -> [(dni, full_name), ...]
ROSTERS = {
    # Google Cloud Digital Leader — grupo A inglés — 101 students
    "2627-DSGAI-2-45810-A": [
        ("02568514", "Adrián Ramos Merino"),
        ("54197882", "Alba García-Casal Monja"),
        ("55020743", "Alejandro Calle Albacete"),
        ("51517680", "Alejandro López García"),
        ("50346077", "Alejandro López Jorge"),
        ("51738218", "Alejandro Molina Navío"),
        ("02787482", "Alfonso Garnica Lacave"),
        ("54494601", "Alvaro Santamarta de Santos"),
        ("54364293", "Antonio Bengoa Guirau"),
        ("54381361", "Antonio Isabelo Ortiz Abellán García"),
        ("Y2882956", "Armando Suárez Rodríguez"),
        ("B00853029", "Camila Escalante Chaverri"),
        ("Y5051716", "Camila Ivana Franquis Lira"),
        ("51506270", "Carla Barrio Orueta"),
        ("06612367", "Carlos Díaz Gutiérrez-Manchón"),
        ("55082653", "Casilda Domecq Domecq"),
        ("51535860", "Cayetano Burgos Pino"),
        ("51530014", "Cristina Clara Bomprezzi de Toro"),
        ("02586275", "Cristóbal Buenadicha Oñate"),
        ("51734680", "Daniel Bobes Martín"),
        ("52909824", "Daniel Vázquez Pomar"),
        ("70275937", "David Fernandez Santamaria"),
        ("BD331966", "David Rodríguez Calle"),
        ("51509500", "Diego Manzanares Pérez-Nievas"),
        ("54534375", "Diego Pérez Cortina"),
        ("05991454", "Federico Carasa Agudo"),
        ("54298460", "Fernando Vela Pérez"),
        ("P19924259", "Ferran Martorell González"),
        ("Z2928117", "Francesco Magistrelli"),
        ("54266306", "Francisco Javier González Iglesias"),
        ("Z0292530", "Gabriel Viale Valdivia"),
        ("54722491", "Gema González de Andrés"),
        ("02580311", "Gonzalo Angulo Ruiz-Cabello"),
        ("30330630", "Gonzalo Astarloa Rodríguez"),
        ("70940348", "Gonzalo Cejuela Valle"),
        ("06647596", "Gonzalo Wiznez Valiente"),
        ("53850550", "Hugo Alonso Rodríguez"),
        ("51729596", "Ignacio Godino Viscasillas"),
        ("02587585", "Ignacio Álvarez Hernanz"),
        ("54023974", "Inés Vilchez Ramirez"),
        ("02773028", "Irene Molina González"),
        ("51558714", "Irene Moreno Arce"),
        ("Z1144421", "Isabella Barros Sourdis"),
        ("50496073", "Izan Gómez Mancheño"),
        ("50338993", "Jacobo López Asiaín Martínez"),
        ("06034850", "Jaime Martín Brime"),
        ("06643046", "Jaime del Castillo Martínez"),
        ("51193180", "Jaime Álvarez-Campana Rodrigo"),
        ("54209168", "Jairo Yuste Chacón"),
        ("51736102", "Javier Abad Terán"),
        ("77174420", "Javier Heredia de León"),
        ("54538298", "Javier Larrea Ramírez"),
        ("39491140", "Jest Eimiell Buenadicha Nuñez"),
        ("54499437", "Jimena Perea Cuerda"),
        ("48175915", "Josep Pujadas Herreros"),
        ("Z3976364", "Juan José Sánchez Cardona"),
        ("03181546", "Juan Morales Morante"),
        ("47319928", "Leire Garrido González"),
        ("72007657", "Lucas Giménez García"),
        ("70839516", "Lucas Martín Martín"),
        ("23833179", "Lucia Morales Andreo"),
        ("11902104", "Lucía María Gordovil Ortiz de Urbina"),
        ("55024354", "Lucía Piqueras Montoto"),
        ("70268524", "Manuel Carlos Gómez González"),
        ("51535117", "Marcos Briceño Nuevo"),
        ("09140535", "Mario Salas Marín"),
        ("50491223", "Marlon Sieira Martínez"),
        ("55024046", "Marta Díaz Monzonis"),
        ("54912029", "Martín de Pablo del Palacio"),
        ("06610023", "María Teresa Solís Rodríguez"),
        ("11086513", "María Velasco Pasamontes"),
        ("54211333", "Mateo Bernabéu Sánchez"),
        ("54353523", "Miguel Fontenla de Alcaraz"),
        ("54721591", "Miguel de Castro González"),
        ("03187690", "Miguel de Simón Estébanez"),
        ("XDE217032", "Mikel Lejarraga Mc Sweeney"),
        ("54719239", "Máximo Ruiz Pavlov"),
        ("54480045", "Natalia Gahete Morillo"),
        ("PA0832328", "Nicolás Méndez Cano"),
        ("53955113", "Nicolás Ortiz Fernández Villaplana"),
        ("54886473", "Nicolás Palazuelos Navarro"),
        ("A9571768", "Omar Andrés Mideros Vega"),
        ("51534092", "Pablo Antelo Guntiñas"),
        ("02588450", "Pablo Hervella Alba"),
        ("77952382", "Pablo Peral Martin"),
        ("02587682", "Pablo Romero Aparicio"),
        ("54932068", "Pablo Álvarez Harguindey"),
        ("51246613", "Pedro Arias Sevillano"),
        ("51502349", "Pepe Ruiz González"),
        ("54493708", "Ricardo Díaz Alcaraz"),
        ("54353531", "Roberto Bolarín Fiel"),
        ("54023358", "Rodrigo Castellanos López"),
        ("54361981", "Samuel Arenas Marhuenda"),
        ("54213938", "Sara Clavero Moreno"),
        ("L4WFW7689", "Tomás Alexander Von Zehmen"),
        ("12457445", "Victoria Isabel Cotes Estévez"),
        ("02759051", "Álvaro Cid Pérez"),
        ("70085353", "Álvaro Escribano Rodríguez-Barba"),
        ("01673344", "Álvaro García Riber"),
        ("51547857", "Álvaro Pérez García"),
        ("54294215", "Ángela Menéndez Reques"),
    ],
    # Visualization and Reporting — grupo ADN-A inglés — 36 students
    "2627-ADN-3-6033-A": [
        ("06024021", "Adriana Moyo Sánchez"),
        ("06031466", "Adriana Nistal Campillo"),
        ("54352724", "Alejandro Sainz Carpio"),
        ("48109544", "Alejandro de la Maza Segura"),
        ("47315562", "Ana Zitao Pérez Martínez"),
        ("47588042", "Andrea García Soria"),
        ("09845826", "Claudia Manzaneque Peña"),
        ("06618119", "Claudia Serrada de Pedraza"),
        ("51007316", "Daira García Gómez"),
        ("06603944", "Daniel Ayala Naranjo"),
        ("54369131", "Diego López Ruiz"),
        ("05952488", "Gonzalo Carrasco Barros"),
        ("54369366", "Gonzalo Salas Dorado"),
        ("48034111", "Gonzalo de Mier Fernández-Caro"),
        ("02566101", "Iván Alba Eguinoa"),
        ("45332592", "Jaime Serna González"),
        ("02729512", "Javier Ruiz Egea"),
        ("54211682", "Jesús Ramírez Vega"),
        ("53846543", "Jorge Asenjo Martín"),
        ("05961361", "Juan Manuel Pedraza Rioboo"),
        ("54495191", "Laura Jiménez Jiménez"),
        ("26936803", "Laura Madrid Espinosa"),
        ("53989108", "Laura Reyero González-Noriega"),
        ("54494079", "Marcos López Domínguez"),
        ("47317452", "Mario Marín Fernández"),
        ("51501099", "Miguel Poudereux López-Barrantes"),
        ("06610675", "Pablo Abad Pérez"),
        ("51484099", "Pablo Palma Pérez"),
        ("54210699", "Pablo de Santos Burgueño"),
        ("54191100", "Paula Esnarrizaga Rodríguez"),
        ("51708892", "Raúl Soligo Sierra"),
        ("71965609", "Rodrigo Requejo Antón"),
        ("49155842", "Sofía González Hernández"),
        ("43924576", "Tomás Herrera Londoño"),
        ("48225548", "Álvaro Adeva Torres"),
        ("54189676", "Álvaro de Celis Muñoz"),
    ],
    # Visualization and Reporting — grupo ADN-AIB1 inglés (incluye AIN1) — 49 students
    "2627-ADN-3-6033-AIB1": [
        ("54298043", "Alejandra Vacas Martín"),
        ("02570498", "Alejandro González Vila"),
        ("48207184", "Alejandro Rodríguez Gil"),
        ("02785614", "Alicia Hoyos Patón"),
        ("51524523", "Ander Amondarain Herrero"),
        ("49431975", "Antonio Rodríguez Tárraga"),
        ("55191002", "Berta María San Juan Cereceda"),
        ("55526581", "Blanca Carrasco Giraldo"),
        ("79182825", "Blanca Hernando Estepa"),
        ("48283049", "Borja Rincón Lozada"),
        ("54192987", "César Alejandro González Rozalén"),
        ("48017647", "Daniel Gradillas Álvarez"),
        ("06589552", "Daniel Vaquerizo González"),
        ("02587664", "Daniel Vaquero Román"),
        ("05468985", "David Trujillo Valero"),
        ("02774225", "Diego Hernández Reales"),
        ("53935218", "Fátima Belén Rocca Flores"),
        ("06005475", "Hugo Domínguez Concejo"),
        ("02781340", "Inés Victoria Ortega Taberna"),
        ("51719270", "Jaime Carrasco Segarra"),
        ("06663348", "Jaime J Escrivá de Romaní Álvarez de Estrada"),
        ("51507462", "Jaime Peñil Guldentops"),
        ("Z2873191", "Javier González Masselli"),
        ("L88NZJM9", "Joel Aime Wyneken"),
        ("06596648", "Jorge García García"),
        ("05953355", "José Otero Jordán"),
        ("Y8858593", "Juan Carlos Alva Pandal"),
        ("54212239", "Juan del Campo Fernández"),
        ("G43018928", "Karla Patricia Casillas Peñaloza"),
        ("CA35038PF", "Laura Venturin"),
        ("02584373", "Marcos Anca Robledo"),
        ("54026395", "Natalia Blanco Toral"),
        ("06620730", "Natalia García García"),
        ("49394335", "Nicolás Parrondo Fernández"),
        ("43223787", "Nicolás Quetglas Sedliacikova"),
        ("11475937", "Pablo Bringas Iturrioz"),
        ("02593580", "Pablo Gómez Rodríguez"),
        ("53992836", "Pablo Peredo López"),
        ("51486970", "Raúl Moreno Villena"),
        ("53996896", "Ricardo Sada González"),
        ("54210272", "Rodrigo María Urrutia Bailly-Bailliere"),
        ("51734949", "Sofía Masucci Muntaner"),
        ("CA00462NQ", "Valentina Santonicola"),
        ("54365801", "Valeria Suárez Voces"),
        ("02554327", "Yago Robles Moreno"),
        ("06604750", "Álvaro Gutiérrez Palomares"),
        ("53992923", "Álvaro Prieto Álvarez"),
        ("05936850", "Álvaro Ruiz Muñoz"),
        ("79076188", "Íñigo Val Martínez"),
    ],
}


def course_id_for(cur, code):
    cur.execute("SELECT id FROM course WHERE code = %s", (code,))
    row = cur.fetchone()
    if not row:
        raise SystemExit(f"Course {code} does not exist — create it first.")
    return row[0]


def upsert_student(cur, dni, full_name, course_code):
    email = f"{dni}@{course_code.lower()}.local"
    cur.execute(
        """
        INSERT INTO app_user (dni, email, full_name, role, is_active)
        VALUES (%s, %s, %s, 'student', true)
        ON CONFLICT (dni) WHERE dni IS NOT NULL DO NOTHING
        RETURNING id
        """,
        (dni, email, full_name),
    )
    row = cur.fetchone()
    if row:
        return row[0], True
    cur.execute("SELECT id FROM app_user WHERE dni = %s", (dni,))
    return cur.fetchone()[0], False


def enrol(cur, course_id, user_id):
    cur.execute(
        """
        INSERT INTO course_enrollment (course_id, user_id, role_in_course)
        VALUES (%s, %s, 'student')
        ON CONFLICT (course_id, user_id) DO NOTHING
        """,
        (course_id, user_id),
    )
    return cur.rowcount > 0


def main():
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            totals = []
            for code, students in ROSTERS.items():
                cid = course_id_for(cur, code)
                created = enrolled = 0
                for dni, name in students:
                    uid, is_new = upsert_student(cur, dni, name, code)
                    created += is_new
                    enrolled += enrol(cur, cid, uid)
                totals.append((code, len(students), created, enrolled))
                print(
                    f"{code}: {len(students)} on roster, "
                    f"{created} new user(s), {enrolled} new enrolment(s)"
                )
        if DRY_RUN:
            conn.rollback()
            print("\nDRY RUN — rolled back, nothing written.")
        else:
            conn.commit()
            print("\nCommitted.")
    except Exception as exc:
        conn.rollback()
        print(f"Error: {exc}")
        sys.exit(1)
    finally:
        conn.close()


if __name__ == "__main__":
    main()

from typing import Dict, Any, Optional

import psycopg2

from .config import DB_NAME, DB_USER, DB_PASSWORD, DB_HOST, DB_PORT


def get_connection():
    return psycopg2.connect(
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD,
        host=DB_HOST,
        port=DB_PORT,
    )


def check_db():
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT 1;")
            cur.fetchone()
    finally:
        conn.close()


# -------------------------------------------------------------------------
# Reusable query helpers
# -------------------------------------------------------------------------


def get_test_info(cur, test_id: int) -> Optional[Dict[str, Any]]:
    """Fetch test info by ID. Returns None if not found."""
    cur.execute(
        """
        SELECT id, course_id, title, description, total_points
        FROM test
        WHERE id = %s
        """,
        (test_id,),
    )
    row = cur.fetchone()
    if row is None:
        return None

    return {
        "id": row[0],
        "course_id": row[1],
        "title": row[2],
        "description": row[3],
        "total_points": float(row[4]) if row[4] is not None else None,
    }


def get_user_by_dni(cur, dni: str) -> Optional[Dict[str, Any]]:
    """Fetch user by DNI. Returns None if not found."""
    cur.execute(
        """
        SELECT id, full_name, email, dni, role
        FROM app_user
        WHERE dni = %s
        """,
        (dni,),
    )
    row = cur.fetchone()
    if row is None:
        return None

    return {
        "id": row[0],
        "full_name": row[1],
        "email": row[2],
        "dni": row[3],
        "role": row[4],
    }

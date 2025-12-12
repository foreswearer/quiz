from fastapi import APIRouter, Query
from ..db import get_connection, get_user_by_dni

router = APIRouter()


@router.get("/users/stats")
def get_user_stats():
    """
    Get user statistics (total users, active users, etc.)
    Active users = users with activity in the last 2 hours.
    Public endpoint - no authentication required.
    """
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            # Get active users count (activity in last 2 hours)
            cur.execute(
                """
                SELECT COUNT(DISTINCT ta.student_id)
                FROM test_attempt ta
                WHERE ta.started_at >= NOW() - INTERVAL '2 hours'
                   OR ta.submitted_at >= NOW() - INTERVAL '2 hours'
                """
            )
            active_count = cur.fetchone()[0] or 0

            # Get inactive users count (no activity in last 2 hours)
            cur.execute(
                """
                SELECT COUNT(*)
                FROM app_user u
                WHERE u.id NOT IN (
                    SELECT DISTINCT ta.student_id
                    FROM test_attempt ta
                    WHERE ta.started_at >= NOW() - INTERVAL '2 hours'
                       OR ta.submitted_at >= NOW() - INTERVAL '2 hours'
                )
                """
            )
            inactive_count = cur.fetchone()[0] or 0

            # Get total users count
            total_count = active_count + inactive_count

            # Get counts by role (for active users only)
            cur.execute(
                """
                SELECT u.role, COUNT(DISTINCT u.id)
                FROM app_user u
                JOIN test_attempt ta ON ta.student_id = u.id
                WHERE ta.started_at >= NOW() - INTERVAL '2 hours'
                   OR ta.submitted_at >= NOW() - INTERVAL '2 hours'
                GROUP BY u.role
                """
            )
            role_counts = {}
            for role, count in cur.fetchall():
                role_counts[role] = count

            return {
                "active_users": active_count,
                "inactive_users": inactive_count,
                "total_users": total_count,
                "by_role": role_counts,
            }
    finally:
        conn.close()


@router.get("/users")
def list_users(
    teacher_dni: str = Query(..., description="Teacher DNI for authorization"),
):
    """
    List all users. Only accessible by teachers.
    """
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            # Verify teacher
            teacher = get_user_by_dni(cur, teacher_dni)
            if teacher is None:
                return {"error": f"user with DNI {teacher_dni} not found"}
            if teacher["role"] != "teacher":
                return {"error": "only teachers can list users"}

            # Get all users
            cur.execute(
                """
                SELECT id, dni, full_name, email, role, is_active
                FROM app_user
                ORDER BY full_name
                """
            )
            rows = cur.fetchall()

            users = []
            for user_id, dni, full_name, email, role, is_active in rows:
                users.append(
                    {
                        "id": user_id,
                        "dni": dni,
                        "full_name": full_name,
                        "email": email,
                        "role": role,
                        "is_active": is_active,
                    }
                )

            return {"users": users}
    finally:
        conn.close()


@router.put("/users/{user_id}/role")
def update_user_role(
    user_id: int,
    teacher_dni: str = Query(..., description="Teacher DNI for authorization"),
    new_role: str = Query(
        ..., description="New role (student, power_student, teacher)"
    ),
):
    """
    Update a user's role. Only accessible by teachers.
    """
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            # Verify teacher
            teacher = get_user_by_dni(cur, teacher_dni)
            if teacher is None:
                return {"error": f"user with DNI {teacher_dni} not found"}
            if teacher["role"] != "teacher":
                return {"error": "only teachers can update roles"}

            # Validate new role
            valid_roles = ["student", "power_student", "teacher", "admin"]
            if new_role not in valid_roles:
                return {
                    "error": f"invalid role. Must be one of: {', '.join(valid_roles)}"
                }

            # Get current user info
            cur.execute(
                "SELECT full_name, role FROM app_user WHERE id = %s", (user_id,)
            )
            user_row = cur.fetchone()
            if user_row is None:
                return {"error": f"user {user_id} not found"}

            old_role = user_row[1]

            # Update role
            cur.execute(
                "UPDATE app_user SET role = %s WHERE id = %s",
                (new_role, user_id),
            )
            conn.commit()

            return {
                "message": f"User role updated from '{old_role}' to '{new_role}'",
                "user_id": user_id,
                "new_role": new_role,
            }
    finally:
        conn.close()

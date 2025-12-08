from typing import Dict, Any, Optional

from fastapi import APIRouter, Query

from ..db import get_connection

router = APIRouter()


# -------------------------------------------------------------------------
# Course endpoints
# -------------------------------------------------------------------------


@router.get("/courses")
def list_courses():
    """List all courses."""
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT id, code, name, description, academic_year, class_group, is_active
                FROM course
                ORDER BY id
                """
            )
            rows = cur.fetchall()
            courses = [
                {
                    "id": r[0],
                    "code": r[1],
                    "name": r[2],
                    "description": r[3],
                    "academic_year": r[4],
                    "class_group": r[5],
                    "is_active": r[6],
                }
                for r in rows
            ]
            return {"courses": courses}
    finally:
        conn.close()


@router.post("/courses")
def create_course(data: dict):
    """Create a new course."""
    code = data.get("code", "").strip()
    name = data.get("name", "").strip()
    description = data.get("description", "").strip() or None
    academic_year = data.get("academic_year")
    class_group = data.get("class_group", "").strip()

    if not code:
        return {"error": "Course code is required"}
    if not name:
        return {"error": "Course name is required"}
    if not academic_year:
        return {"error": "Academic year is required"}
    if not class_group:
        return {"error": "Class group is required"}

    conn = get_connection()
    try:
        with conn.cursor() as cur:
            # Check if code already exists
            cur.execute("SELECT id FROM course WHERE code = %s", (code,))
            if cur.fetchone():
                return {"error": f"Course with code '{code}' already exists"}

            cur.execute(
                """
                INSERT INTO course (code, name, description, academic_year, class_group)
                VALUES (%s, %s, %s, %s, %s)
                RETURNING id
                """,
                (code, name, description, academic_year, class_group),
            )
            course_id = cur.fetchone()[0]
            conn.commit()

            return {
                "message": "Course created",
                "course": {
                    "id": course_id,
                    "code": code,
                    "name": name,
                    "description": description,
                    "academic_year": academic_year,
                    "class_group": class_group,
                },
            }
    finally:
        conn.close()


@router.put("/courses/{course_id}")
def update_course(course_id: int, data: dict):
    """Update a course."""
    code = data.get("code", "").strip()
    name = data.get("name", "").strip()
    description = data.get("description", "").strip() or None
    academic_year = data.get("academic_year")
    class_group = data.get("class_group", "").strip()

    if not code:
        return {"error": "Course code is required"}
    if not name:
        return {"error": "Course name is required"}
    if not academic_year:
        return {"error": "Academic year is required"}
    if not class_group:
        return {"error": "Class group is required"}

    conn = get_connection()
    try:
        with conn.cursor() as cur:
            # Check course exists
            cur.execute("SELECT id FROM course WHERE id = %s", (course_id,))
            if not cur.fetchone():
                return {"error": f"Course {course_id} not found"}

            # Check code uniqueness (excluding current course)
            cur.execute(
                "SELECT id FROM course WHERE code = %s AND id != %s",
                (code, course_id),
            )
            if cur.fetchone():
                return {"error": f"Course with code '{code}' already exists"}

            cur.execute(
                """
                UPDATE course
                SET code = %s, name = %s, description = %s, 
                    academic_year = %s, class_group = %s
                WHERE id = %s
                """,
                (code, name, description, academic_year, class_group, course_id),
            )
            conn.commit()

            return {
                "message": "Course updated",
                "course": {
                    "id": course_id,
                    "code": code,
                    "name": name,
                    "description": description,
                    "academic_year": academic_year,
                    "class_group": class_group,
                },
            }
    finally:
        conn.close()


@router.delete("/courses/{course_id}")
def delete_course(course_id: int):
    """Delete a course (only if no questions reference it)."""
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            # Check course exists
            cur.execute(
                "SELECT id, code, name FROM course WHERE id = %s",
                (course_id,),
            )
            row = cur.fetchone()
            if not row:
                return {"error": f"Course {course_id} not found"}

            # Check for questions using this course
            cur.execute(
                "SELECT COUNT(*) FROM question_bank WHERE course_id = %s",
                (course_id,),
            )
            count = cur.fetchone()[0]
            if count > 0:
                return {
                    "error": f"Cannot delete course: {count} questions reference it"
                }

            cur.execute("DELETE FROM course WHERE id = %s", (course_id,))
            conn.commit()

            return {
                "message": "Course deleted",
                "deleted": {"id": row[0], "code": row[1], "name": row[2]},
            }
    finally:
        conn.close()


# -------------------------------------------------------------------------
# Question Bank endpoints (prefixed with /api to avoid route conflicts)
# -------------------------------------------------------------------------


def _fetch_question_with_options(cur, question_id: int) -> Optional[Dict[str, Any]]:
    """Helper to fetch a question with its options."""
    cur.execute(
        """
        SELECT
            qb.id,
            qb.course_id,
            c.code AS course_code,
            c.name AS course_name,
            qb.question_text,
            qb.question_type,
            qb.default_points
        FROM question_bank qb
        JOIN course c ON c.id = qb.course_id
        WHERE qb.id = %s
        """,
        (question_id,),
    )
    row = cur.fetchone()
    if not row:
        return None

    # Get options
    cur.execute(
        """
        SELECT id, option_text, is_correct, order_index
        FROM question_option
        WHERE question_id = %s
        ORDER BY order_index
        """,
        (question_id,),
    )
    opt_rows = cur.fetchall()
    options = [
        {
            "id": o[0],
            "text": o[1],
            "is_correct": bool(o[2]),
            "order_index": o[3],
        }
        for o in opt_rows
    ]

    return {
        "id": row[0],
        "course_id": row[1],
        "course_code": row[2],
        "course_name": row[3],
        "question_text": row[4],
        "question_type": row[5],
        "default_points": float(row[6]) if row[6] else None,
        "options": options,
    }


@router.get("/api/question-bank")
def list_questions(
    course_id: Optional[int] = Query(None, description="Filter by course ID"),
):
    """List all questions, optionally filtered by course."""
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            if course_id:
                cur.execute(
                    """
                    SELECT qb.id
                    FROM question_bank qb
                    WHERE qb.course_id = %s
                    ORDER BY qb.id
                    """,
                    (course_id,),
                )
            else:
                cur.execute(
                    """
                    SELECT qb.id
                    FROM question_bank qb
                    ORDER BY qb.id
                    """
                )

            q_ids = [r[0] for r in cur.fetchall()]
            questions = []
            for q_id in q_ids:
                q = _fetch_question_with_options(cur, q_id)
                if q:
                    questions.append(q)

            return {"questions": questions}
    finally:
        conn.close()


@router.get("/api/question-bank/{question_id}")
def get_question(question_id: int):
    """Get a single question with its options."""
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            question = _fetch_question_with_options(cur, question_id)
            if not question:
                return {"error": f"Question {question_id} not found"}

            return {"question": question}
    finally:
        conn.close()


@router.post("/api/question-bank")
def create_question(data: dict):
    """Create a new question with options."""
    course_id = data.get("course_id")
    question_text = data.get("question_text", "").strip()
    question_type = data.get("question_type", "single_choice")
    default_points = data.get("default_points", 0.5)
    options = data.get("options", [])

    if not course_id:
        return {"error": "course_id is required"}
    if not question_text:
        return {"error": "question_text is required"}
    if not options or len(options) < 2:
        return {"error": "At least 2 options are required"}

    # Validate at least one correct option
    has_correct = any(o.get("is_correct") for o in options)
    if not has_correct:
        return {"error": "At least one option must be correct"}

    conn = get_connection()
    try:
        with conn.cursor() as cur:
            # Check course exists
            cur.execute("SELECT id FROM course WHERE id = %s", (course_id,))
            if not cur.fetchone():
                return {"error": f"Course {course_id} not found"}

            # Insert question
            cur.execute(
                """
                INSERT INTO question_bank (course_id, question_text, question_type, default_points)
                VALUES (%s, %s, %s, %s)
                RETURNING id
                """,
                (course_id, question_text, question_type, default_points),
            )
            question_id = cur.fetchone()[0]

            # Insert options
            for idx, opt in enumerate(options):
                cur.execute(
                    """
                    INSERT INTO question_option (question_id, option_text, is_correct, order_index)
                    VALUES (%s, %s, %s, %s)
                    """,
                    (
                        question_id,
                        opt.get("text", "").strip(),
                        bool(opt.get("is_correct", False)),
                        idx + 1,
                    ),
                )

            conn.commit()

            return {
                "message": "Question created",
                "question_id": question_id,
            }
    finally:
        conn.close()


@router.put("/api/question-bank/{question_id}")
def update_question(question_id: int, data: dict):
    """Update a question and its options."""
    question_text = data.get("question_text", "").strip()
    question_type = data.get("question_type")
    default_points = data.get("default_points")
    options = data.get("options")

    if not question_text:
        return {"error": "question_text is required"}

    conn = get_connection()
    try:
        with conn.cursor() as cur:
            # Check question exists
            cur.execute(
                "SELECT id, course_id FROM question_bank WHERE id = %s",
                (question_id,),
            )
            row = cur.fetchone()
            if not row:
                return {"error": f"Question {question_id} not found"}

            # Update question
            cur.execute(
                """
                UPDATE question_bank
                SET question_text = %s,
                    question_type = COALESCE(%s, question_type),
                    default_points = COALESCE(%s, default_points)
                WHERE id = %s
                """,
                (question_text, question_type, default_points, question_id),
            )

            # Update options if provided
            if options is not None:
                if len(options) < 2:
                    return {"error": "At least 2 options are required"}

                has_correct = any(o.get("is_correct") for o in options)
                if not has_correct:
                    return {"error": "At least one option must be correct"}

                # Delete old options
                cur.execute(
                    "DELETE FROM question_option WHERE question_id = %s",
                    (question_id,),
                )

                # Insert new options
                for idx, opt in enumerate(options):
                    cur.execute(
                        """
                        INSERT INTO question_option (question_id, option_text, is_correct, order_index)
                        VALUES (%s, %s, %s, %s)
                        """,
                        (
                            question_id,
                            opt.get("text", "").strip(),
                            bool(opt.get("is_correct", False)),
                            idx + 1,
                        ),
                    )

            conn.commit()

            return {"message": "Question updated", "question_id": question_id}
    finally:
        conn.close()


@router.delete("/api/question-bank/{question_id}")
def delete_question(question_id: int):
    """Delete a question and its options."""
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            # Check question exists
            cur.execute(
                "SELECT id, question_text FROM question_bank WHERE id = %s",
                (question_id,),
            )
            row = cur.fetchone()
            if not row:
                return {"error": f"Question {question_id} not found"}

            # Check if question is used in any test
            cur.execute(
                "SELECT COUNT(*) FROM test_question WHERE question_id = %s",
                (question_id,),
            )
            count = cur.fetchone()[0]
            if count > 0:
                return {
                    "error": f"Cannot delete: question is used in {count} test(s)"
                }

            # Delete options first (foreign key)
            cur.execute(
                "DELETE FROM question_option WHERE question_id = %s",
                (question_id,),
            )

            # Delete question
            cur.execute(
                "DELETE FROM question_bank WHERE id = %s",
                (question_id,),
            )

            conn.commit()

            return {
                "message": "Question deleted",
                "deleted_id": question_id,
            }
    finally:
        conn.close()
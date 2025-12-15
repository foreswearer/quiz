from typing import Dict, Any, Optional, Tuple

from fastapi import APIRouter, Query

from ..db import get_connection

router = APIRouter()


# -------------------------------------------------------------------------
# Helper functions
# -------------------------------------------------------------------------


def _extract_course_data(data: dict) -> Tuple[Optional[Dict[str, Any]], Optional[str]]:
    """
    Extract and validate course data from request.
    Returns (course_data, error_message).
    If error_message is not None, course_data will be None.
    """
    code = data.get("code", "").strip()
    name = data.get("name", "").strip()
    description = data.get("description", "").strip() or None
    academic_year = data.get("academic_year")
    class_group = data.get("class_group", "").strip()

    if not code:
        return None, "Course code is required"
    if not name:
        return None, "Course name is required"
    if not academic_year:
        return None, "Academic year is required"
    if not class_group:
        return None, "Class group is required"

    return {
        "code": code,
        "name": name,
        "description": description,
        "academic_year": academic_year,
        "class_group": class_group,
    }, None


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
    course_data, error = _extract_course_data(data)
    if error:
        return {"error": error}

    conn = get_connection()
    try:
        with conn.cursor() as cur:
            # Check if code already exists
            cur.execute("SELECT id FROM course WHERE code = %s", (course_data["code"],))
            if cur.fetchone():
                return {
                    "error": f"Course with code '{course_data['code']}' already exists"
                }

            cur.execute(
                """
                INSERT INTO course (code, name, description, academic_year, class_group)
                VALUES (%s, %s, %s, %s, %s)
                RETURNING id
                """,
                (
                    course_data["code"],
                    course_data["name"],
                    course_data["description"],
                    course_data["academic_year"],
                    course_data["class_group"],
                ),
            )
            course_id = cur.fetchone()[0]
            conn.commit()

            return {
                "message": "Course created",
                "course": {"id": course_id, **course_data},
            }
    finally:
        conn.close()


@router.put("/courses/{course_id}")
def update_course(course_id: int, data: dict):
    """Update a course."""
    course_data, error = _extract_course_data(data)
    if error:
        return {"error": error}

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
                (course_data["code"], course_id),
            )
            if cur.fetchone():
                return {
                    "error": f"Course with code '{course_data['code']}' already exists"
                }

            cur.execute(
                """
                UPDATE course
                SET code = %s, name = %s, description = %s, 
                    academic_year = %s, class_group = %s
                WHERE id = %s
                """,
                (
                    course_data["code"],
                    course_data["name"],
                    course_data["description"],
                    course_data["academic_year"],
                    course_data["class_group"],
                    course_id,
                ),
            )
            conn.commit()

            return {
                "message": "Course updated",
                "course": {"id": course_id, **course_data},
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


@router.get("/api/question-bank/export")
def export_questions_as_json(
    course_code: str = Query(..., description="Course code to export questions from")
):
    """
    Export all questions for a course in JSON format (same format as upload).

    Returns JSON in the format:
    {
        "course_code": "2526-45810-A",
        "questions": [
            {
                "question_text": "What is...",
                "question_type": "single_choice",
                "default_points": 0.5,
                "options": [
                    {"text": "Option A", "is_correct": false},
                    {"text": "Option B", "is_correct": true}
                ]
            }
        ]
    }
    """
    if not course_code:
        return {"error": "course_code is required"}

    conn = get_connection()
    try:
        with conn.cursor() as cur:
            # Check course exists
            cur.execute("SELECT id, name FROM course WHERE code = %s", (course_code,))
            row = cur.fetchone()
            if not row:
                return {"error": f"Course with code '{course_code}' not found"}

            course_id, course_name = row

            # Get all questions for this course
            cur.execute(
                """
                SELECT id, question_text, question_type, default_points
                FROM question_bank
                WHERE course_id = %s
                ORDER BY id
                """,
                (course_id,),
            )
            question_rows = cur.fetchall()

            questions = []
            for q_id, q_text, q_type, q_points in question_rows:
                # Get options for this question
                cur.execute(
                    """
                    SELECT option_text, is_correct
                    FROM question_option
                    WHERE question_id = %s
                    ORDER BY order_index
                    """,
                    (q_id,),
                )
                option_rows = cur.fetchall()

                options = [
                    {"text": opt_text, "is_correct": bool(is_correct)}
                    for opt_text, is_correct in option_rows
                ]

                questions.append({
                    "question_text": q_text,
                    "question_type": q_type,
                    "default_points": float(q_points) if q_points else 0.5,
                    "options": options,
                })

            return {
                "course_code": course_code,
                "questions": questions,
            }
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

                # Get existing options
                cur.execute(
                    """
                    SELECT id, order_index 
                    FROM question_option 
                    WHERE question_id = %s 
                    ORDER BY order_index
                    """,
                    (question_id,),
                )
                existing_options = cur.fetchall()
                existing_by_index = {row[1]: row[0] for row in existing_options}

                # Update or insert options
                for idx, opt in enumerate(options):
                    order_index = idx + 1
                    option_text = opt.get("text", "").strip()
                    is_correct = bool(opt.get("is_correct", False))

                    if order_index in existing_by_index:
                        # Update existing option (preserves ID for student_answer FK)
                        cur.execute(
                            """
                            UPDATE question_option
                            SET option_text = %s, is_correct = %s
                            WHERE id = %s
                            """,
                            (option_text, is_correct, existing_by_index[order_index]),
                        )
                    else:
                        # Insert new option
                        cur.execute(
                            """
                            INSERT INTO question_option 
                            (question_id, option_text, is_correct, order_index)
                            VALUES (%s, %s, %s, %s)
                            """,
                            (question_id, option_text, is_correct, order_index),
                        )

                # Delete extra options only if not referenced by student_answer
                for order_index, option_id in existing_by_index.items():
                    if order_index > len(options):
                        cur.execute(
                            "SELECT COUNT(*) FROM student_answer WHERE selected_option_id = %s",
                            (option_id,),
                        )
                        if cur.fetchone()[0] == 0:
                            cur.execute(
                                "DELETE FROM question_option WHERE id = %s",
                                (option_id,),
                            )
                        # If referenced, leave it (can't delete)

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
                return {"error": f"Cannot delete: question is used in {count} test(s)"}

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


@router.post("/api/question-bank/upload")
def upload_questions_from_json(data: dict):
    """
    Upload multiple questions from JSON format.

    Expected JSON format:
    {
        "course_code": "2526-45810-A",
        "replace_existing": false,  (optional, defaults to false)
        "questions": [
            {
                "question_text": "What is...",
                "question_type": "single_choice",  (optional, defaults to "single_choice")
                "default_points": 0.5,  (optional, defaults to 0.5)
                "options": [
                    {"text": "Option A", "is_correct": false},
                    {"text": "Option B", "is_correct": true},
                    {"text": "Option C", "is_correct": false}
                ]
            }
        ]
    }
    """
    course_code = data.get("course_code", "").strip()
    questions = data.get("questions", [])
    replace_existing = data.get("replace_existing", False)

    if not course_code:
        return {"error": "course_code is required"}

    if not questions or not isinstance(questions, list):
        return {"error": "questions array is required"}

    conn = get_connection()
    try:
        with conn.cursor() as cur:
            # Check course exists
            cur.execute("SELECT id, name FROM course WHERE code = %s", (course_code,))
            row = cur.fetchone()
            if not row:
                return {"error": f"Course with code '{course_code}' not found"}

            course_id, course_name = row

            deleted_count = 0

            # Handle replace mode: delete existing questions
            if replace_existing:
                # First check if any existing questions are used in tests
                cur.execute(
                    """
                    SELECT COUNT(DISTINCT tq.question_id)
                    FROM test_question tq
                    JOIN question_bank qb ON qb.id = tq.question_id
                    WHERE qb.course_id = %s
                    """,
                    (course_id,),
                )
                used_count = cur.fetchone()[0]
                if used_count > 0:
                    return {
                        "error": f"Cannot replace: {used_count} existing question(s) are used in tests"
                    }

                # Count questions to be deleted
                cur.execute(
                    "SELECT COUNT(*) FROM question_bank WHERE course_id = %s",
                    (course_id,),
                )
                deleted_count = cur.fetchone()[0]

                # Delete options first (foreign key constraint)
                cur.execute(
                    """
                    DELETE FROM question_option
                    WHERE question_id IN (
                        SELECT id FROM question_bank WHERE course_id = %s
                    )
                    """,
                    (course_id,),
                )

                # Then delete questions
                cur.execute(
                    "DELETE FROM question_bank WHERE course_id = %s",
                    (course_id,),
                )

            created_count = 0
            errors = []

            for idx, q_data in enumerate(questions):
                question_text = q_data.get("question_text", "").strip()
                question_type = q_data.get("question_type", "single_choice")
                default_points = q_data.get("default_points", 0.5)
                options = q_data.get("options", [])

                # Validate question
                if not question_text:
                    errors.append(f"Question {idx + 1}: question_text is required")
                    continue

                if not options or len(options) < 2:
                    errors.append(
                        f"Question {idx + 1}: At least 2 options are required"
                    )
                    continue

                has_correct = any(o.get("is_correct") for o in options)
                if not has_correct:
                    errors.append(
                        f"Question {idx + 1}: At least one option must be correct"
                    )
                    continue

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
                for opt_idx, opt in enumerate(options):
                    cur.execute(
                        """
                        INSERT INTO question_option (question_id, option_text, is_correct, order_index)
                        VALUES (%s, %s, %s, %s)
                        """,
                        (
                            question_id,
                            opt.get("text", "").strip(),
                            bool(opt.get("is_correct", False)),
                            opt_idx + 1,
                        ),
                    )

                created_count += 1

            conn.commit()

            result = {
                "message": f"Successfully uploaded {created_count} question(s) to course '{course_name}'",
                "course_code": course_code,
                "created_count": created_count,
                "errors": errors if errors else None,
            }

            if deleted_count > 0:
                result["deleted_count"] = deleted_count

            return result
    finally:
        conn.close()

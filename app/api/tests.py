from typing import List, Dict, Any

from fastapi import APIRouter, Query

from ..db import get_connection, get_test_info, get_user_by_dni
from ..schemas import RandomTestRequest

router = APIRouter()


@router.get("/available_tests")
def available_tests():
    """
    List all tests with basic information and number of questions.
    """
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT
                    t.id,
                    t.course_id,
                    t.title,
                    t.description,
                    COALESCE(t.total_points, 0)::float AS total_points,
                    COUNT(tq.question_id) AS num_questions
                FROM test t
                LEFT JOIN test_question tq ON tq.test_id = t.id
                GROUP BY t.id, t.course_id, t.title, t.description, t.total_points
                ORDER BY t.id
                """
            )
            rows = cur.fetchall()

            tests: List[Dict[str, Any]] = []
            for tid, course_id, title, desc, total_points, num_questions in rows:
                tests.append(
                    {
                        "id": tid,
                        "course_id": course_id,
                        "title": title,
                        "description": desc,
                        "total_points": total_points,
                        "num_questions": int(num_questions),
                    }
                )
            return {"tests": tests}
    finally:
        conn.close()


@router.get("/tests/{test_id}")
def get_test(test_id: int):
    """
    Get a test definition, including questions and options (with is_correct flag).
    """
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            test = get_test_info(cur, test_id)
            if test is None:
                return {"error": f"test {test_id} not found"}

            cur.execute(
                """
                SELECT
                    tq.question_id,
                    tq.order_index,
                    qb.question_text,
                    qb.question_type,
                    qb.default_points
                FROM test_question tq
                JOIN question_bank qb ON qb.id = tq.question_id
                WHERE tq.test_id = %s
                ORDER BY tq.order_index
                """,
                (test_id,),
            )
            question_rows = cur.fetchall()

            questions: List[Dict[str, Any]] = []
            for q_id, order_idx, q_text, q_type, q_points in question_rows:
                cur.execute(
                    """
                    SELECT id, option_text, is_correct, order_index
                    FROM question_option
                    WHERE question_id = %s
                    ORDER BY order_index
                    """,
                    (q_id,),
                )
                options_rows = cur.fetchall()
                options: List[Dict[str, Any]] = []
                for opt_id, opt_text, is_correct, opt_order in options_rows:
                    options.append(
                        {
                            "id": opt_id,
                            "text": opt_text,
                            "order_index": opt_order,
                            "is_correct": bool(is_correct),
                        }
                    )

                questions.append(
                    {
                        "id": q_id,
                        "order_index": order_idx,
                        "text": q_text,
                        "type": q_type,
                        "points": float(q_points) if q_points is not None else None,
                        "options": options,
                    }
                )

            return {
                "test": test,
                "questions": questions,
            }
    finally:
        conn.close()


@router.post("/tests/random_from_bank")
def create_random_test(req: RandomTestRequest):
    """
    Create a random test from the question bank for a given course.
    """
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT id, name FROM course WHERE code = %s",
                (req.course_code,),
            )
            crow = cur.fetchone()
            if crow is None:
                return {"error": f"course with code {req.course_code} not found"}
            course_id, course_name = crow

            # Get the user who is creating the test
            user = get_user_by_dni(cur, req.student_dni)
            if user is None:
                return {"error": f"user with DNI {req.student_dni} not found"}
            user_id = user["id"]

            # Get available questions count and cap requested number
            cur.execute(
                "SELECT COUNT(*) FROM question_bank WHERE course_id = %s",
                (course_id,),
            )
            available_questions = cur.fetchone()[0] or 0

            if available_questions == 0:
                return {"error": f"no questions available for course {req.course_code}"}

            n = min(max(1, req.num_questions), available_questions)

            # Use custom title if provided, otherwise use default
            if req.title and req.title.strip():
                title = req.title.strip()
            else:
                title = f"Random {n} – created by {req.student_dni}"

            description = (
                f"Random {n}-question test from course "
                f"{req.course_code} ({course_name})."
            )

            # Set test configuration from request
            test_type = req.test_type or "quiz"
            time_limit = req.time_limit_minutes
            max_attempts = req.max_attempts  # None = unlimited
            randomize_q = req.randomize_questions if req.randomize_questions is not None else False
            randomize_o = req.randomize_options if req.randomize_options is not None else False

            cur.execute(
                """
                INSERT INTO test (
                    course_id, title, description, total_points, created_by,
                    test_type, time_limit_minutes, max_attempts,
                    randomize_questions, randomize_options
                )
                VALUES (%s, %s, %s, NULL, %s, %s, %s, %s, %s, %s)
                RETURNING id
                """,
                (course_id, title, description, user_id, test_type, time_limit,
                 max_attempts, randomize_q, randomize_o),
            )
            test_id = cur.fetchone()[0]

            cur.execute(
                """
                INSERT INTO test_question (test_id, question_id, order_index, points)
                SELECT
                    %s AS test_id,
                    qb.id AS question_id,
                    row_number() OVER () AS order_index,
                    qb.default_points
                FROM question_bank qb
                WHERE qb.course_id = %s
                ORDER BY random()
                LIMIT %s
                RETURNING question_id
                """,
                (test_id, course_id, n),
            )
            inserted_questions = cur.fetchall()
            actual_n = len(inserted_questions)

            cur.execute(
                """
                UPDATE test
                SET total_points = %s
                WHERE id = %s
                """,
                (actual_n * 0.5, test_id),
            )

            conn.commit()

            return {
                "test_id": test_id,
                "title": title,
                "description": description,
                "num_questions": actual_n,
            }
    finally:
        conn.close()


@router.delete("/tests/{test_id}")
def delete_test(
    test_id: int,
    dni: str = Query(
        ...,
        description="User DNI (teacher can delete any, students can delete their own)",
    ),
):
    """
    Delete a test and ALL associated results.
    Teachers can delete any test.
    Students and power_students can delete tests they created.
    """
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            user = get_user_by_dni(cur, dni)
            if user is None:
                return {"error": f"user with DNI {dni} not found"}

            test = get_test_info(cur, test_id)
            if test is None:
                return {"error": f"test {test_id} not found"}

            # Get test details including creator
            cur.execute(
                "SELECT created_by FROM test WHERE id = %s",
                (test_id,),
            )
            test_row = cur.fetchone()
            test_created_by = test_row[0] if test_row else None

            # Authorization check
            is_teacher = user["role"] == "teacher"
            is_owner = test_created_by == user["id"]

            if not is_teacher and not is_owner:
                return {"error": "you can only delete tests you created"}
            test_title = test["title"]

            cur.execute(
                "SELECT COUNT(*) FROM test_attempt WHERE test_id = %s",
                (test_id,),
            )
            attempts_count = cur.fetchone()[0] or 0

            cur.execute(
                """
                SELECT COUNT(*) FROM student_answer
                WHERE attempt_id IN (SELECT id FROM test_attempt WHERE test_id = %s)
                """,
                (test_id,),
            )
            answers_count = cur.fetchone()[0] or 0

            cur.execute(
                "SELECT COUNT(*) FROM test_question WHERE test_id = %s",
                (test_id,),
            )
            tq_count = cur.fetchone()[0] or 0

            cur.execute(
                """
                DELETE FROM student_answer
                WHERE attempt_id IN (SELECT id FROM test_attempt WHERE test_id = %s)
                """,
                (test_id,),
            )
            cur.execute("DELETE FROM test_attempt WHERE test_id = %s", (test_id,))
            cur.execute("DELETE FROM test_question WHERE test_id = %s", (test_id,))
            cur.execute("DELETE FROM test WHERE id = %s", (test_id,))

            conn.commit()

            return {
                "deleted_test_id": test_id,
                "deleted_test_title": test_title,
                "deleted_attempts": attempts_count,
                "deleted_answers": answers_count,
                "deleted_test_questions": tq_count,
            }
    finally:
        conn.close()


@router.put("/tests/{test_id}")
def rename_test(test_id: int, data: dict):
    """
    Rename a test. Only teachers can rename tests.
    """
    title = data.get("title")
    teacher_dni = data.get("teacher_dni")

    if not title or not title.strip():
        return {"error": "Title cannot be empty"}
    if not teacher_dni:
        return {"error": "Teacher DNI required"}

    conn = get_connection()
    try:
        with conn.cursor() as cur:
            user = get_user_by_dni(cur, teacher_dni)
            if user is None:
                return {"error": f"User with DNI {teacher_dni} not found"}
            if user["role"] != "teacher":
                return {"error": "Only teachers can rename tests"}

            test = get_test_info(cur, test_id)
            if test is None:
                return {"error": f"Test {test_id} not found"}

            cur.execute(
                "UPDATE test SET title = %s WHERE id = %s",
                (title.strip(), test_id),
            )
            conn.commit()

            return {"message": f"Test renamed to '{title.strip()}'"}
    finally:
        conn.close()


@router.post("/attempts/{attempt_id}/study_mode")
def create_study_mode_test(
    attempt_id: int,
    dni: str = Query(..., description="Student DNI"),
):
    """
    Create a study mode test containing only the questions that were answered incorrectly
    in the given attempt.
    """
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            # Verify user
            user = get_user_by_dni(cur, dni)
            if user is None:
                return {"error": f"user with DNI {dni} not found"}

            # Get attempt info
            cur.execute(
                """
                SELECT ta.test_id, ta.student_id, t.course_id, t.title
                FROM test_attempt ta
                JOIN test t ON t.id = ta.test_id
                WHERE ta.id = %s
                """,
                (attempt_id,),
            )
            attempt_row = cur.fetchone()
            if attempt_row is None:
                return {"error": f"attempt {attempt_id} not found"}

            original_test_id, student_id, course_id, original_title = attempt_row

            # Verify this is the student's attempt
            if student_id != user["id"]:
                return {"error": "you can only create study mode for your own attempts"}

            # Get questions answered incorrectly
            cur.execute(
                """
                SELECT DISTINCT sa.question_id, qb.default_points
                FROM student_answer sa
                JOIN question_bank qb ON qb.id = sa.question_id
                WHERE sa.attempt_id = %s AND sa.is_correct = FALSE
                ORDER BY sa.question_id
                """,
                (attempt_id,),
            )
            wrong_questions = cur.fetchall()

            if not wrong_questions:
                return {
                    "error": "no incorrect answers found - you got everything right!"
                }

            # Create new test
            title = f"Study Mode: {original_title}"
            description = (
                f"Practice test with {len(wrong_questions)} questions you got wrong"
            )

            cur.execute(
                """
                INSERT INTO test (course_id, title, description, total_points, created_by)
                VALUES (%s, %s, %s, %s, %s)
                RETURNING id
                """,
                (
                    course_id,
                    title,
                    description,
                    sum(points for _, points in wrong_questions),
                    user["id"],
                ),
            )
            new_test_id = cur.fetchone()[0]

            # Insert questions
            for idx, (question_id, points) in enumerate(wrong_questions, 1):
                cur.execute(
                    """
                    INSERT INTO test_question (test_id, question_id, order_index, points)
                    VALUES (%s, %s, %s, %s)
                    """,
                    (new_test_id, question_id, idx, points),
                )

            conn.commit()

            return {
                "test_id": new_test_id,
                "title": title,
                "description": description,
                "num_questions": len(wrong_questions),
            }
    finally:
        conn.close()

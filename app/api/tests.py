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
                    t.title,
                    t.description,
                    COALESCE(t.total_points, 0)::float AS total_points,
                    COUNT(tq.question_id) AS num_questions
                FROM test t
                LEFT JOIN test_question tq ON tq.test_id = t.id
                GROUP BY t.id, t.title, t.description, t.total_points
                ORDER BY t.id
                """
            )
            rows = cur.fetchall()

            tests: List[Dict[str, Any]] = []
            for tid, title, desc, total_points, num_questions in rows:
                tests.append(
                    {
                        "id": tid,
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

            n = max(1, req.num_questions)

            title = f"Random {n} – created by {req.student_dni}"
            description = (
                f"Random {n}-question test from course "
                f"{req.course_code} ({course_name})."
            )

            cur.execute(
                """
                INSERT INTO test (course_id, title, description, total_points)
                VALUES (%s, %s, %s, NULL)
                RETURNING id
                """,
                (course_id, title, description),
            )
            test_id = cur.fetchone()[0]

            cur.execute(
                """
                WITH q AS (
                    SELECT
                        qb.id AS question_id,
                        row_number() OVER (ORDER BY random()) AS rn
                    FROM question_bank qb
                    WHERE qb.course_id = %s
                )
                INSERT INTO test_question (test_id, question_id, order_index, points)
                SELECT
                    %s AS test_id,
                    q.question_id,
                    q.rn AS order_index,
                    qb.default_points
                FROM q
                JOIN question_bank qb ON qb.id = q.question_id
                WHERE q.rn <= %s
                RETURNING question_id
                """,
                (course_id, test_id, n),
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
    teacher_dni: str = Query(..., description="Teacher DNI (must have role='teacher')"),
):
    """
    Delete a test and ALL associated results.
    Requires a teacher DNI.
    """
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            user = get_user_by_dni(cur, teacher_dni)
            if user is None:
                return {"error": f"user with DNI {teacher_dni} not found"}
            if user["role"] != "teacher":
                return {"error": f"DNI {teacher_dni} is not a teacher"}

            test = get_test_info(cur, test_id)
            if test is None:
                return {"error": f"test {test_id} not found"}
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

from typing import List, Dict, Any, Optional

from fastapi import APIRouter, Query

from .db import get_connection, check_db
from .schemas import SubmitRequest, RandomTestRequest

router = APIRouter()


@router.get("/health")
def health():
    try:
        check_db()
        return {"status": "ok", "db": "ok"}
    except Exception as e:
        return {"status": "error", "db": str(e)}


@router.get("/version")
def version():
    """Return the application version from VERSION file."""
    try:
        with open("VERSION", "r") as f:
            ver = f.read().strip()
        return {"version": ver}
    except FileNotFoundError:
        return {"version": "unknown"}


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
                return {"error": f"test {test_id} not found"}

            test = {
                "id": row[0],
                "course_id": row[1],
                "title": row[2],
                "description": row[3],
                "total_points": float(row[4]) if row[4] is not None else None,
            }

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


@router.post("/tests/{test_id}/start")
def start_test(
    test_id: int,
    student_dni: str = Query(..., description="User DNI / ID (unique in app_user)"),
):
    """
    Start a test attempt for the user identified by DNI.
    Teachers can also start attempts (for self-testing).
    Returns attempt info including max_attempts and current attempt count.
    """
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            # Any user (student or teacher) with that DNI
            cur.execute(
                """
                SELECT id, full_name, email, dni, role
                FROM app_user
                WHERE dni = %s
                """,
                (student_dni,),
            )
            student_row = cur.fetchone()
            if student_row is None:
                return {"error": f"user not found for DNI {student_dni}"}

            student_id, student_name, s_email, s_dni, s_role = student_row

            # Get test info INCLUDING max_attempts
            cur.execute(
                """
                SELECT id, course_id, title, description, total_points, max_attempts
                FROM test
                WHERE id = %s
                """,
                (test_id,),
            )
            test_row = cur.fetchone()
            if test_row is None:
                return {"error": f"test {test_id} not found"}

            test_info = {
                "id": test_row[0],
                "course_id": test_row[1],
                "title": test_row[2],
                "description": test_row[3],
                "total_points": float(test_row[4]) if test_row[4] is not None else None,
                "max_attempts": test_row[5],  # Can be NULL (unlimited)
            }

            # Count existing attempts for this user on this test
            cur.execute(
                """
                SELECT COUNT(*)
                FROM test_attempt
                WHERE test_id = %s AND student_id = %s
                """,
                (test_id, student_id),
            )
            current_attempts = cur.fetchone()[0] or 0

            # Check if max attempts reached (only if max_attempts is set)
            max_attempts = test_info["max_attempts"]
            if max_attempts is not None and current_attempts >= max_attempts:
                return {
                    "error": f"Maximum attempts reached ({max_attempts}).",
                    "max_attempts": max_attempts,
                    "current_attempts": current_attempts,
                    "can_retry": False,
                }

            # Next attempt number
            attempt_number = current_attempts + 1

            # Max score: 0.5 per question
            cur.execute(
                """
                SELECT COUNT(*)
                FROM test_question
                WHERE test_id = %s
                """,
                (test_id,),
            )
            num_questions = cur.fetchone()[0] or 0
            max_score = num_questions * 0.5

            cur.execute(
                """
                INSERT INTO test_attempt (
                    test_id,
                    student_id,
                    attempt_number,
                    status,
                    max_score,
                    auto_graded
                )
                VALUES (%s, %s, %s, 'in_progress', %s, FALSE)
                RETURNING id
                """,
                (test_id, student_id, attempt_number, max_score),
            )
            attempt_id = cur.fetchone()[0]

            # Questions for this test (without is_correct flags)
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
                    SELECT id, option_text, order_index
                    FROM question_option
                    WHERE question_id = %s
                    ORDER BY order_index
                    """,
                    (q_id,),
                )
                options_rows = cur.fetchall()
                options: List[Dict[str, Any]] = [
                    {"id": opt_id, "text": opt_text, "order_index": opt_order}
                    for (opt_id, opt_text, opt_order) in options_rows
                ]

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

            conn.commit()

            # Calculate attempts remaining
            attempts_remaining = None
            if max_attempts is not None:
                attempts_remaining = max_attempts - attempt_number

            return {
                "attempt_id": attempt_id,
                "attempt_number": attempt_number,
                "max_attempts": max_attempts,  # NULL means unlimited
                "attempts_remaining": attempts_remaining,
                "can_retry": attempts_remaining is None or attempts_remaining > 0,
                "student": {
                    "id": student_id,
                    "name": student_name,
                    "email": s_email,
                    "dni": s_dni,
                    "role": s_role,
                },
                "test": {
                    **test_info,
                    "max_score": max_score,
                },
                "questions": questions,
            }
    finally:
        conn.close()


@router.post("/attempts/{attempt_id}/submit")
def submit_attempt(attempt_id: int, payload: SubmitRequest):
    """
    Scoring:
      - correct: +0.5
      - incorrect: -1 / num_options
      - unanswered: 0
    Returns per-question details for UI highlighting.
    """
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            # Attempt info
            cur.execute(
                """
                SELECT test_id, student_id, status, max_score
                FROM test_attempt
                WHERE id = %s
                """,
                (attempt_id,),
            )
            row = cur.fetchone()
            if row is None:
                return {"error": f"attempt {attempt_id} not found"}

            test_id, student_id, status, max_score = row
            if status != "in_progress":
                return {
                    "error": f"attempt {attempt_id} is not in progress (status={status})"
                }

            # If no max_score yet, compute from number of questions
            if max_score is None:
                cur.execute(
                    """
                    SELECT COUNT(*)
                    FROM test_question
                    WHERE test_id = %s
                    """,
                    (test_id,),
                )
                num_questions = cur.fetchone()[0] or 0
                max_score = num_questions * 0.5

            # Map question_id -> selected_option_id
            answers_by_q = {
                a.question_id: a.selected_option_id for a in payload.answers
            }

            total_score = 0.0
            details: List[Dict[str, Any]] = []

            # All questions in this test
            cur.execute(
                """
                SELECT question_id
                FROM test_question
                WHERE test_id = %s
                """,
                (test_id,),
            )
            q_ids = [r[0] for r in cur.fetchall()]

            for question_id in q_ids:
                selected_option_id: Optional[int] = answers_by_q.get(question_id)

                cur.execute(
                    """
                    SELECT id, is_correct
                    FROM question_option
                    WHERE question_id = %s
                    """,
                    (question_id,),
                )
                opt_rows = cur.fetchall()
                if not opt_rows:
                    continue

                num_options = len(opt_rows)
                correct_option_ids = [oid for (oid, is_corr) in opt_rows if is_corr]

                is_correct: Optional[bool] = None
                if selected_option_id is not None:
                    is_correct = any(
                        (oid == selected_option_id and is_corr)
                        for (oid, is_corr) in opt_rows
                    )

                # Scoring
                if selected_option_id is None:
                    earned = 0.0
                elif is_correct:
                    earned = 0.5
                else:
                    earned = -1.0 / float(num_options)

                total_score += earned

                # Persist answer - only if an option was actually selected
                if selected_option_id is not None and selected_option_id != 0:
                    cur.execute(
                        """
                        INSERT INTO student_answer (
                            attempt_id  , question_id,
                            selected_option_id,
                            is_correct, score
                        )
                        VALUES (%s, %s, %s, %s, %s)
                        ON CONFLICT (attempt_id, question_id) DO UPDATE
                        SET selected_option_id = EXCLUDED.selected_option_id,
                            is_correct = EXCLUDED.is_correct,
                            score = EXCLUDED.score,
                            graded_at = NOW()
                        """,
                        (
                            attempt_id,
                            question_id,
                            selected_option_id,
                            is_correct,
                            earned,
                        ),
                    )

                details.append(
                    {
                        "question_id": question_id,
                        "selected_option_id": selected_option_id,
                        "correct_option_ids": correct_option_ids,
                        "is_correct": is_correct,
                        "score": earned,
                    }
                )

            # Final percentage
            percentage = 0.0
            if max_score and float(max_score) > 0.0:
                percentage = (total_score / float(max_score)) * 100.0

            cur.execute(
                """
                UPDATE test_attempt
                SET status = 'graded',
                    submitted_at = NOW(),
                    score = %s,
                    percentage = %s,
                    auto_graded = TRUE
                WHERE id = %s
                """,
                (total_score, percentage, attempt_id),
            )

            conn.commit()

            return {
                "attempt_id": attempt_id,
                "test_id": test_id,
                "student_id": student_id,
                "score": total_score,
                "max_score": float(max_score),
                "percentage": percentage,
                "details": details,
            }
    finally:
        conn.close()


@router.get("/tests/{test_id}/results")
def get_test_results(test_id: int):
    """
    Per-test summary and per-student best result.
    (Everybody can see this; podium is exposed in /tests/{id}/analytics.)
    """
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            # Test info
            cur.execute(
                """
                SELECT id, course_id, title, description, total_points
                FROM test
                WHERE id = %s
                """,
                (test_id,),
            )
            trow = cur.fetchone()
            if trow is None:
                return {"error": f"test {test_id} not found"}

            test_info = {
                "id": trow[0],
                "course_id": trow[1],
                "title": trow[2],
                "description": trow[3],
                "total_points": float(trow[4]) if trow[4] is not None else None,
            }

            # Summary
            cur.execute(
                """
                SELECT
                    COUNT(DISTINCT student_id) AS num_students,
                    AVG(percentage)           AS avg_percentage,
                    MIN(percentage)           AS min_percentage,
                    MAX(percentage)           AS max_percentage
                FROM test_attempt
                WHERE test_id = %s
                  AND status = 'graded'
                """,
                (test_id,),
            )
            srow = cur.fetchone()
            num_students = srow[0] or 0
            avg_percentage = float(srow[1]) if srow[1] is not None else None
            min_percentage = float(srow[2]) if srow[2] is not None else None
            max_percentage = float(srow[3]) if srow[3] is not None else None

            summary = {
                "num_students": num_students,
                "avg_percentage": avg_percentage,
                "min_percentage": min_percentage,
                "max_percentage": max_percentage,
            }

            # Best result per student
            cur.execute(
                """
                SELECT
                    ta.student_id,
                    u.full_name,
                    u.email,
                    u.dni,
                    COUNT(*)                  AS attempts,
                    MAX(ta.score)             AS best_score,
                    MAX(ta.percentage)        AS best_percentage,
                    MAX(ta.submitted_at)      AS last_submitted_at
                FROM test_attempt ta
                JOIN app_user u ON u.id = ta.student_id
                WHERE ta.test_id = %s
                  AND ta.status = 'graded'
                GROUP BY ta.student_id, u.full_name, u.email, u.dni
                ORDER BY u.full_name
                """,
                (test_id,),
            )
            rows = cur.fetchall()

            results: List[Dict[str, Any]] = []
            for (
                student_id,
                full_name,
                email,
                dni,
                attempts,
                best_score,
                best_percentage,
                last_submitted_at,
            ) in rows:
                results.append(
                    {
                        "student_id": student_id,
                        "name": full_name,
                        "email": email,
                        "dni": dni,
                        "attempts": int(attempts),
                        "best_score": float(best_score)
                        if best_score is not None
                        else None,
                        "best_percentage": float(best_percentage)
                        if best_percentage is not None
                        else None,
                        "last_submitted_at": last_submitted_at.isoformat()
                        if last_submitted_at is not None
                        else None,
                    }
                )

            return {
                "test": test_info,
                "summary": summary,
                "results": results,
            }
    finally:
        conn.close()


@router.get("/student/{dni}/attempts")
def student_attempts(dni: str):
    """
    Attempts for a user identified by DNI.
    Works for both students and teachers (role is returned).
    """
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT id, full_name, email, dni, role
                FROM app_user
                WHERE dni = %s
                """,
                (dni,),
            )
            srow = cur.fetchone()
            if srow is None:
                return {"error": f"user with DNI {dni} not found"}

            student_id, full_name, email, sdni, role = srow

            cur.execute(
                """
                SELECT
                    ta.id,
                    ta.test_id,
                    t.title,
                    ta.attempt_number,
                    ta.score,
                    ta.max_score,
                    ta.percentage,
                    ta.status,
                    ta.submitted_at
                FROM test_attempt ta
                JOIN test t ON t.id = ta.test_id
                WHERE ta.student_id = %s
                ORDER BY ta.submitted_at NULLS LAST, ta.id
                """,
                (student_id,),
            )
            rows = cur.fetchall()

            attempts: List[Dict[str, Any]] = []
            for (
                attempt_id,
                test_id,
                test_title,
                attempt_number,
                score,
                max_score,
                percentage,
                status,
                submitted_at,
            ) in rows:
                attempts.append(
                    {
                        "attempt_id": attempt_id,
                        "test_id": test_id,
                        "test_title": test_title,
                        "attempt_number": attempt_number,
                        "score": float(score) if score is not None else None,
                        "max_score": float(max_score)
                        if max_score is not None
                        else None,
                        "percentage": float(percentage)
                        if percentage is not None
                        else None,
                        "status": status,
                        "submitted_at": submitted_at.isoformat()
                        if submitted_at is not None
                        else None,
                    }
                )

            return {
                "student": {
                    "id": student_id,
                    "dni": sdni,
                    "name": full_name,
                    "email": email,
                    "role": role,
                },
                "attempts": attempts,
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
            # Resolve course
            cur.execute(
                "SELECT id, name FROM course WHERE code = %s",
                (req.course_code,),
            )
            crow = cur.fetchone()
            if crow is None:
                return {"error": f"course with code {req.course_code} not found"}
            course_id, course_name = crow

            n = max(1, req.num_questions)

            # Use custom title if provided, otherwise generate default
            if req.title and req.title.strip():
                title = req.title.strip()
            else:
                title = f"Random {n} – created by {req.student_dni}"
            description = (
                f"Random {n}-question test from course "
                f"{req.course_code} ({course_name})."
            )

            cur.execute(
                """
                INSERT INTO test (course_id, title, description, total_points, max_attempts)
                VALUES (%s, %s, %s, NULL, %s)
                RETURNING id
                """,
                (course_id, title, description, req.max_attempts),
            )
            test_id = cur.fetchone()[0]

            # Random questions
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


# -------------------------------------------------------------------------
# Teacher / analytics endpoints
# -------------------------------------------------------------------------


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
            # Check teacher
            cur.execute(
                """
                SELECT id, full_name, role
                FROM app_user
                WHERE dni = %s
                """,
                (teacher_dni,),
            )
            urow = cur.fetchone()
            if urow is None:
                return {"error": f"user with DNI {teacher_dni} not found"}
            teacher_id, teacher_name, role = urow
            if role != "teacher":
                return {"error": f"DNI {teacher_dni} is not a teacher"}

            # Check test exists
            cur.execute(
                "SELECT id, title FROM test WHERE id = %s",
                (test_id,),
            )
            trow = cur.fetchone()
            if trow is None:
                return {"error": f"test {test_id} not found"}
            _, test_title = trow

            # Counts before deletion
            cur.execute(
                """
                SELECT COUNT(*)
                FROM test_attempt
                WHERE test_id = %s
                """,
                (test_id,),
            )
            attempts_count = cur.fetchone()[0] or 0

            cur.execute(
                """
                SELECT COUNT(*)
                FROM student_answer
                WHERE attempt_id IN (
                    SELECT id FROM test_attempt WHERE test_id = %s
                )
                """,
                (test_id,),
            )
            answers_count = cur.fetchone()[0] or 0

            cur.execute(
                """
                SELECT COUNT(*)
                FROM test_question
                WHERE test_id = %s
                """,
                (test_id,),
            )
            tq_count = cur.fetchone()[0] or 0

            # Delete in safe order
            cur.execute(
                """
                DELETE FROM student_answer
                WHERE attempt_id IN (
                    SELECT id FROM test_attempt WHERE test_id = %s
                )
                """,
                (test_id,),
            )

            cur.execute(
                """
                DELETE FROM test_attempt
                WHERE test_id = %s
                """,
                (test_id,),
            )

            cur.execute(
                """
                DELETE FROM test_question
                WHERE test_id = %s
                """,
                (test_id,),
            )

            cur.execute(
                """
                DELETE FROM test
                WHERE id = %s
                """,
                (test_id,),
            )

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
            # Verify teacher
            cur.execute(
                "SELECT id, role FROM app_user WHERE dni = %s",
                (teacher_dni,),
            )
            user_row = cur.fetchone()
            if user_row is None:
                return {"error": f"User with DNI {teacher_dni} not found"}
            if user_row[1] != "teacher":
                return {"error": "Only teachers can rename tests"}

            # Check test exists
            cur.execute("SELECT id FROM test WHERE id = %s", (test_id,))
            if cur.fetchone() is None:
                return {"error": f"Test {test_id} not found"}

            # Update title
            cur.execute(
                "UPDATE test SET title = %s WHERE id = %s",
                (title.strip(), test_id),
            )
            conn.commit()

            return {"message": f"Test renamed to '{title.strip()}'"}
    finally:
        conn.close()


@router.get("/tests/{test_id}/analytics")
def test_analytics(test_id: int):
    """
    Teacher-style analytics, but accessible to everyone:
      - Most failed/correct question
      - Most failed/correct answer
      - Attempts stats
      - Podium (best single score, best average score)
    Podium uses FULL NAMES, not DNI.
    """
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            # Test info
            cur.execute(
                """
                SELECT id, course_id, title, description, total_points
                FROM test
                WHERE id = %s
                """,
                (test_id,),
            )
            trow = cur.fetchone()
            if trow is None:
                return {"error": f"test {test_id} not found"}

            test_info = {
                "id": trow[0],
                "course_id": trow[1],
                "title": trow[2],
                "description": trow[3],
                "total_points": float(trow[4]) if trow[4] is not None else None,
            }

            # Attempts stats
            cur.execute(
                """
                SELECT
                    COUNT(*)                 AS total_attempts,
                    COUNT(DISTINCT student_id) AS num_students,
                    AVG(percentage)          AS avg_percentage
                FROM test_attempt
                WHERE test_id = %s
                  AND status = 'graded'
                """,
                (test_id,),
            )
            arow = cur.fetchone()
            total_attempts = arow[0] or 0
            num_students = arow[1] or 0
            avg_percentage = float(arow[2]) if arow[2] is not None else None

            avg_attempts_per_student: Optional[float] = None
            if num_students > 0:
                avg_attempts_per_student = total_attempts / float(num_students)

            attempts_stats = {
                "total_attempts": total_attempts,
                "num_students": num_students,
                "avg_attempts_per_student": avg_attempts_per_student,
                "avg_percentage": avg_percentage,
            }

            # Question stats (correct / wrong counts per question)
            cur.execute(
                """
                SELECT
                    sa.question_id,
                    qb.question_text,
                    SUM(CASE WHEN sa.is_correct THEN 1 ELSE 0 END) AS correct_count,
                    SUM(CASE WHEN sa.is_correct THEN 0 ELSE 1 END) AS wrong_count,
                    COUNT(*) AS total_answers
                FROM student_answer sa
                JOIN test_attempt ta ON ta.id = sa.attempt_id
                JOIN question_bank qb ON qb.id = sa.question_id
                WHERE ta.test_id = %s
                  AND ta.status = 'graded'
                GROUP BY sa.question_id, qb.question_text
                """,
                (test_id,),
            )
            qrows = cur.fetchall()

            def to_q_dict(row):
                q_id, qtext, correct_count, wrong_count, total_answers = row
                total_answers = total_answers or 0
                wrong_rate = (
                    float(wrong_count) / float(total_answers)
                    if total_answers > 0
                    else None
                )
                correct_rate = (
                    float(correct_count) / float(total_answers)
                    if total_answers > 0
                    else None
                )
                return {
                    "question_id": q_id,
                    "text": qtext,
                    "correct_count": int(correct_count),
                    "wrong_count": int(wrong_count),
                    "total_answers": int(total_answers),
                    "wrong_rate": wrong_rate,
                    "correct_rate": correct_rate,
                }

            most_failed_question = None
            most_correct_question = None
            if qrows:
                most_failed_question = to_q_dict(
                    max(qrows, key=lambda r: r[3])  # wrong_count index 3
                )
                most_correct_question = to_q_dict(
                    max(qrows, key=lambda r: r[2])  # correct_count index 2
                )

            # Answer stats (correct / wrong counts per option)
            cur.execute(
                """
                SELECT
                    qo.id AS option_id,
                    qo.question_id,
                    qb.question_text,
                    qo.option_text,
                    qo.is_correct,
                    SUM(CASE WHEN sa.is_correct THEN 1 ELSE 0 END) AS correct_selected,
                    SUM(CASE WHEN sa.is_correct THEN 0 ELSE 1 END) AS wrong_selected,
                    COUNT(*) AS times_selected
                FROM student_answer sa
                JOIN question_option qo ON qo.id = sa.selected_option_id
                JOIN question_bank qb ON qb.id = qo.question_id
                JOIN test_attempt ta ON ta.id = sa.attempt_id
                WHERE ta.test_id = %s
                  AND ta.status = 'graded'
                GROUP BY
                    qo.id,
                    qo.question_id,
                    qb.question_text,
                    qo.option_text,
                    qo.is_correct
                """,
                (test_id,),
            )
            arows = cur.fetchall()

            def to_opt_dict(row):
                (
                    opt_id,
                    question_id,
                    question_text,
                    option_text,
                    is_correct,
                    correct_selected,
                    wrong_selected,
                    times_selected,
                ) = row
                times_selected = times_selected or 0
                wrong_rate = (
                    float(wrong_selected) / float(times_selected)
                    if times_selected > 0
                    else None
                )
                correct_rate = (
                    float(correct_selected) / float(times_selected)
                    if times_selected > 0
                    else None
                )
                return {
                    "option_id": opt_id,
                    "question_id": question_id,
                    "question_text": question_text,
                    "option_text": option_text,
                    "is_correct": bool(is_correct),
                    "correct_selected": int(correct_selected),
                    "wrong_selected": int(wrong_selected),
                    "times_selected": int(times_selected),
                    "wrong_rate": wrong_rate,
                    "correct_rate": correct_rate,
                }

            most_failed_answer = None
            most_correct_answer = None
            if arows:
                # Most failed = incorrect option with highest wrong_selected
                incorrect_rows = [r for r in arows if not r[4]]  # is_correct index 4
                if incorrect_rows:
                    r = max(
                        incorrect_rows, key=lambda r: r[6]
                    )  # wrong_selected index 6
                    most_failed_answer = to_opt_dict(r)

                # Most correct = correct option with highest correct_selected
                correct_rows = [r for r in arows if r[4]]  # is_correct index 4
                if correct_rows:
                    r = max(
                        correct_rows, key=lambda r: r[5]
                    )  # correct_selected index 5
                    most_correct_answer = to_opt_dict(r)

            # Podium: best single score (percentage)
            cur.execute(
                """
                SELECT
                    ta.student_id,
                    u.full_name,
                    u.email,
                    u.dni,
                    MAX(ta.percentage) AS best_percentage
                FROM test_attempt ta
                JOIN app_user u ON u.id = ta.student_id
                WHERE ta.test_id = %s
                  AND ta.status = 'graded'
                GROUP BY ta.student_id, u.full_name, u.email, u.dni
                ORDER BY best_percentage DESC
                LIMIT 3
                """,
                (test_id,),
            )
            prow_best = cur.fetchall()
            podium_best_single: List[Dict[str, Any]] = []
            for student_id, full_name, email, dni, best_percentage in prow_best:
                podium_best_single.append(
                    {
                        "student_id": student_id,
                        "name": full_name,  # FULL NAME for podium
                        "email": email,
                        "dni": dni,
                        "best_percentage": float(best_percentage)
                        if best_percentage is not None
                        else None,
                    }
                )

            # Podium: best average score (percentage)
            cur.execute(
                """
                SELECT
                    ta.student_id,
                    u.full_name,
                    u.email,
                    u.dni,
                    AVG(ta.percentage) AS avg_percentage
                FROM test_attempt ta
                JOIN app_user u ON u.id = ta.student_id
                WHERE ta.test_id = %s
                  AND ta.status = 'graded'
                GROUP BY ta.student_id, u.full_name, u.email, u.dni
                ORDER BY avg_percentage DESC
                LIMIT 3
                """,
                (test_id,),
            )
            prow_avg = cur.fetchall()
            podium_best_average: List[Dict[str, Any]] = []
            for student_id, full_name, email, dni, avg_percentage in prow_avg:
                podium_best_average.append(
                    {
                        "student_id": student_id,
                        "name": full_name,  # FULL NAME for podium
                        "email": email,
                        "dni": dni,
                        "avg_percentage": float(avg_percentage)
                        if avg_percentage is not None
                        else None,
                    }
                )

            analytics = {
                "attempts_stats": attempts_stats,
                "most_failed_question": most_failed_question,
                "most_correct_question": most_correct_question,
                "most_failed_answer": most_failed_answer,
                "most_correct_answer": most_correct_answer,
                "podium_best_single": podium_best_single,
                "podium_best_average": podium_best_average,
            }

            return {
                "test": test_info,
                "analytics": analytics,
            }
    finally:
        conn.close()


@router.get("/teacher/dashboard_overview")
def teacher_dashboard_overview(
    teacher_dni: str = Query(..., description="Teacher DNI (must have role='teacher')"),
):
    """
    High-level teacher dashboard overview. /tests/

    Returns:
      - summary: global KPIs
      - tests: per-test stats
      - attempts_over_time: daily attempts and average percentage
      - hardest_questions: questions with the highest wrong rate
    """
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            # 1) Check teacher
            cur.execute(
                """
                SELECT id, full_name, role
                FROM app_user
                WHERE dni = %s
                """,
                (teacher_dni,),
            )
            urow = cur.fetchone()
            if urow is None:
                return {"error": f"user with DNI {teacher_dni} not found"}
            teacher_id, teacher_name, role = urow
            if role != "teacher":
                return {"error": f"DNI {teacher_dni} is not a teacher"}

            # 2) Global summary KPIs
            # total students
            cur.execute(
                """
                SELECT COUNT(*) 
                FROM app_user
                WHERE role = 'student'
                """
            )
            total_students = cur.fetchone()[0] or 0

            # total tests
            cur.execute("SELECT COUNT(*) FROM test")
            total_tests = cur.fetchone()[0] or 0

            # total attempts
            cur.execute("SELECT COUNT(*) FROM test_attempt")
            total_attempts = cur.fetchone()[0] or 0

            # attempts last 7 days (graded)
            cur.execute(
                """
                SELECT COUNT(*)
                FROM test_attempt
                WHERE status = 'graded'
                  AND submitted_at >= NOW() - INTERVAL '7 days'
                """
            )
            attempts_last_7_days = cur.fetchone()[0] or 0

            # average percentage (graded attempts only)
            cur.execute(
                """
                SELECT AVG(percentage)
                FROM test_attempt
                WHERE status = 'graded'
                """
            )
            avg_percentage_row = cur.fetchone()[0]
            avg_percentage = (
                float(avg_percentage_row) if avg_percentage_row is not None else None
            )

            summary = {
                "teacher": {
                    "id": teacher_id,
                    "name": teacher_name,
                    "dni": teacher_dni,
                },
                "total_students": int(total_students),
                "total_tests": int(total_tests),
                "total_attempts": int(total_attempts),
                "attempts_last_7_days": int(attempts_last_7_days),
                "avg_percentage": avg_percentage,
            }

            # 3) Per-test stats
            cur.execute(
                """
                SELECT
                    t.id,
                    t.title,
                    COUNT(ta.id) AS attempts,
                    AVG(ta.percentage) AS avg_percentage,
                    MIN(ta.percentage) AS min_percentage,
                    MAX(ta.percentage) AS max_percentage
                FROM test t
                LEFT JOIN test_attempt ta
                    ON ta.test_id = t.id
                   AND ta.status = 'graded'
                GROUP BY t.id, t.title
                ORDER BY t.id
                """
            )
            rows = cur.fetchall()
            tests: List[Dict[str, Any]] = []
            for (
                test_id,
                title,
                attempts,
                avg_pct,
                min_pct,
                max_pct,
            ) in rows:
                tests.append(
                    {
                        "id": test_id,
                        "title": title,
                        "attempts": int(attempts or 0),
                        "avg_percentage": float(avg_pct)
                        if avg_pct is not None
                        else None,
                        "min_percentage": float(min_pct)
                        if min_pct is not None
                        else None,
                        "max_percentage": float(max_pct)
                        if max_pct is not None
                        else None,
                    }
                )

            # 4) Attempts over time (graded attempts per day)
            cur.execute(
                """
                SELECT
                    DATE_TRUNC('day', submitted_at)::date AS day,
                    COUNT(*) AS attempts,
                    AVG(percentage) AS avg_percentage
                FROM test_attempt
                WHERE status = 'graded'
                GROUP BY DATE_TRUNC('day', submitted_at)::date
                ORDER BY day
                """
            )
            rows = cur.fetchall()
            attempts_over_time: List[Dict[str, Any]] = []
            for day, attempts, avg_pct in rows:
                attempts_over_time.append(
                    {
                        "day": day.isoformat(),
                        "attempts": int(attempts or 0),
                        "avg_percentage": float(avg_pct)
                        if avg_pct is not None
                        else None,
                    }
                )

            # 5) Hardest questions (highest wrong rate across all tests)
            cur.execute(
                """
                SELECT
                    sa.question_id,
                    qb.question_text,
                    SUM(CASE WHEN sa.is_correct THEN 1 ELSE 0 END) AS correct_count,
                    SUM(CASE WHEN sa.is_correct THEN 0 ELSE 1 END) AS wrong_count,
                    COUNT(*) AS total_answers
                FROM student_answer sa
                JOIN question_bank qb ON qb.id = sa.question_id
                JOIN test_attempt ta ON ta.id = sa.attempt_id
                WHERE ta.status = 'graded'
                GROUP BY sa.question_id, qb.question_text
                HAVING COUNT(*) > 0
                ORDER BY wrong_count DESC
                LIMIT 10
                """
            )
            rows = cur.fetchall()
            hardest_questions: List[Dict[str, Any]] = []
            for (
                question_id,
                question_text,
                correct_count,
                wrong_count,
                total_answers,
            ) in rows:
                total_answers = total_answers or 0
                wrong_rate: Optional[float] = None
                correct_rate: Optional[float] = None
                if total_answers > 0:
                    wrong_rate = float(wrong_count) / float(total_answers)
                    correct_rate = float(correct_count) / float(total_answers)
                hardest_questions.append(
                    {
                        "question_id": question_id,
                        "text": question_text,
                        "correct_count": int(correct_count or 0),
                        "wrong_count": int(wrong_count or 0),
                        "total_answers": int(total_answers),
                        "wrong_rate": wrong_rate,
                        "correct_rate": correct_rate,
                    }
                )

            return {
                "summary": summary,
                "tests": tests,
                "attempts_over_time": attempts_over_time,
                "hardest_questions": hardest_questions,
            }
    finally:
        conn.close()

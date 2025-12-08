from typing import List, Dict, Any, Optional

from fastapi import APIRouter, Query

from ..db import get_connection, get_test_info, get_user_by_dni
from ..schemas import SubmitRequest

router = APIRouter()


@router.post("/tests/{test_id}/start")
def start_test(
    test_id: int,
    student_dni: str = Query(..., description="User DNI / ID (unique in app_user)"),
):
    """
    Start a test attempt for the user identified by DNI.
    Teachers can also start attempts (for self-testing).
    """
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            # Any user (student or teacher) with that DNI
            user = get_user_by_dni(cur, student_dni)
            if user is None:
                return {"error": f"user not found for DNI {student_dni}"}

            student_id = user["id"]

            test = get_test_info(cur, test_id)
            if test is None:
                return {"error": f"test {test_id} not found"}

            # Next attempt number
            cur.execute(
                """
                SELECT COALESCE(MAX(attempt_number), 0) + 1
                FROM test_attempt
                WHERE test_id = %s AND student_id = %s
                """,
                (test_id, student_id),
            )
            attempt_number = cur.fetchone()[0]

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

            return {
                "attempt_id": attempt_id,
                "attempt_number": attempt_number,
                "student": {
                    "id": user["id"],
                    "name": user["full_name"],
                    "email": user["email"],
                    "dni": user["dni"],
                    "role": user["role"],
                },
                "test": {
                    **test,
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

                # Persist answer
                if selected_option_id is not None:
                    cur.execute(
                        """
                        INSERT INTO student_answer (
                            attempt_id, question_id,
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


@router.get("/student/{dni}/attempts")
def student_attempts(dni: str):
    """
    Attempts for a user identified by DNI.
    Works for both students and teachers (role is returned).
    """
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            user = get_user_by_dni(cur, dni)
            if user is None:
                return {"error": f"user with DNI {dni} not found"}

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
                (user["id"],),
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
                    "id": user["id"],
                    "dni": user["dni"],
                    "name": user["full_name"],
                    "email": user["email"],
                    "role": user["role"],
                },
                "attempts": attempts,
            }
    finally:
        conn.close()

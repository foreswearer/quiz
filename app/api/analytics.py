from typing import List, Dict, Any, Optional

from fastapi import APIRouter, Query

from ..db import get_connection, get_test_info, get_user_by_dni

router = APIRouter()


@router.get("/tests/{test_id}/results")
def get_test_results(test_id: int):
    """
    Per-test summary and per-student best result.
    (Everybody can see this; podium is exposed in /tests/{id}/analytics.)
    """
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            test = get_test_info(cur, test_id)
            if test is None:
                return {"error": f"test {test_id} not found"}

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
                "test": test,
                "summary": summary,
                "results": results,
            }
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
            test = get_test_info(cur, test_id)
            if test is None:
                return {"error": f"test {test_id} not found"}

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
                "test": test,
                "analytics": analytics,
            }
    finally:
        conn.close()


@router.get("/teacher/dashboard_overview")
def teacher_dashboard_overview(
    teacher_dni: str = Query(..., description="Teacher DNI (must have role='teacher')"),
):
    """
    High-level teacher dashboard overview.

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
            user = get_user_by_dni(cur, teacher_dni)
            if user is None:
                return {"error": f"user with DNI {teacher_dni} not found"}
            if user["role"] != "teacher":
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
                    "id": user["id"],
                    "name": user["full_name"],
                    "dni": user["dni"],
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
#!/usr/bin/env python3
"""
Test PPTX parsing without database connection.
"""

from pptx_parser import parse_pptx_questions


if __name__ == "__main__":
    pptx_path = "question_pptx/Cloud Digital Leader - Practice questions.pptx"
    questions = parse_pptx_questions(pptx_path)

    print(f"\n{'=' * 80}")
    print(f"PARSED {len(questions)} QUESTIONS")
    print(f"{'=' * 80}\n")

    # Show first 3 and last 3 questions
    print("First 3 questions:")
    for q in questions[:3]:
        print(f"\nQ{q['question_number']}: {q['question_text'][:80]}...")
        for idx, opt in enumerate(q["options"]):
            marker = "✓" if idx == q["correct_index"] else " "
            print(f"  [{marker}] {opt[:70]}")

    print("\n" + "-" * 80 + "\n")

    print("Last 3 questions:")
    for q in questions[-3:]:
        print(f"\nQ{q['question_number']}: {q['question_text'][:80]}...")
        for idx, opt in enumerate(q["options"]):
            marker = "✓" if idx == q["correct_index"] else " "
            print(f"  [{marker}] {opt[:70]}")

    print(f"\n{'=' * 80}")
    print(
        f"Question numbers range: {questions[0]['question_number']} to {questions[-1]['question_number']}"
    )
    print(f"Total questions: {len(questions)}")
    print(f"{'=' * 80}")

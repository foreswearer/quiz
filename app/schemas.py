from typing import List, Optional
from pydantic import BaseModel, field_validator, model_validator


class Answer(BaseModel):
    question_id: int
    selected_option_id: int


class SubmitRequest(BaseModel):
    answers: List[Answer]


class RandomTestRequest(BaseModel):
    student_dni: str
    num_questions: int = 20
    course_code: str = "2526-45810-A"
    title: Optional[str] = None  # Custom test name (optional)
    max_attempts: Optional[int] = None  # None = unlimited attempts
    time_limit_minutes: Optional[int] = None  # Time limit in minutes
    test_type: Optional[str] = "quiz"  # quiz, exam, or practice
    randomize_questions: Optional[bool] = False  # Shuffle question order
    randomize_options: Optional[bool] = False  # Shuffle answer options

    @model_validator(mode='after')
    def set_defaults_by_test_type(self):
        """
        Apply default values based on test type if not explicitly provided.
        Practice: unlimited attempts, no time limit
        Quiz: 2 attempts, 30 minutes
        Exam: 1 attempt, 60 minutes
        """
        test_type = self.test_type or "quiz"

        if test_type == "practice":
            if self.max_attempts is None:
                self.max_attempts = None  # unlimited
            if self.time_limit_minutes is None:
                self.time_limit_minutes = None  # no limit
        elif test_type == "quiz":
            if self.max_attempts is None:
                self.max_attempts = 2
            if self.time_limit_minutes is None:
                self.time_limit_minutes = 30
        elif test_type == "exam":
            if self.max_attempts is None:
                self.max_attempts = 1
            if self.time_limit_minutes is None:
                self.time_limit_minutes = 60

        return self

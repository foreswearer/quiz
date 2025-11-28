from typing import List
from pydantic import BaseModel


class Answer(BaseModel):
    question_id: int
    selected_option_id: int




class SubmitRequest(BaseModel):
    answers: List[Answer]


class RandomTestRequest(BaseModel):
    student_dni: str
    num_questions: int = 20
    course_code: str = "2526-45810-A"


class UpdateTestRequest(BaseModel):
    title: str
    teacher_dni: str

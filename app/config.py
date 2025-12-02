import os

DB_NAME = os.getenv("QUIZ_DB_NAME", "quiz_platform")
DB_USER = os.getenv("QUIZ_DB_USER", "quiz_user")
DB_PASSWORD = os.getenv("QUIZ_DB_PASSWORD", "C0gum3l0s")
DB_HOST = os.getenv("QUIZ_DB_HOST", "localhost")
DB_PORT = int(os.getenv("QUIZ_DB_PORT", "5432"))

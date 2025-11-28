-- Users
CREATE TABLE IF NOT EXISTS app_user (
    id SERIAL PRIMARY KEY,
    dni VARCHAR(50) UNIQUE NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100),
    role VARCHAR(20) NOT NULL -- 'student' or 'teacher'
);

-- Courses
CREATE TABLE IF NOT EXISTS course (
    id SERIAL PRIMARY KEY,
    code VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL
);

-- Question Bank
CREATE TABLE IF NOT EXISTS question_bank (
    id SERIAL PRIMARY KEY,
    course_id INTEGER REFERENCES course(id),
    question_text TEXT NOT NULL,
    question_type VARCHAR(20) NOT NULL, -- 'multiple_choice'
    default_points FLOAT DEFAULT 0.5
);

-- Question Options
CREATE TABLE IF NOT EXISTS question_option (
    id SERIAL PRIMARY KEY,
    question_id INTEGER REFERENCES question_bank(id),
    option_text TEXT NOT NULL,
    is_correct BOOLEAN DEFAULT FALSE,
    order_index INTEGER DEFAULT 0
);

-- Tests
CREATE TABLE IF NOT EXISTS test (
    id SERIAL PRIMARY KEY,
    course_id INTEGER REFERENCES course(id),
    title VARCHAR(200) NOT NULL,
    description TEXT,
    total_points FLOAT
);

-- Test Questions (Many-to-Many)
CREATE TABLE IF NOT EXISTS test_question (
    test_id INTEGER REFERENCES test(id),
    question_id INTEGER REFERENCES question_bank(id),
    order_index INTEGER DEFAULT 0,
    points FLOAT DEFAULT 0.5,
    PRIMARY KEY (test_id, question_id)
);

-- Test Attempts
CREATE TABLE IF NOT EXISTS test_attempt (
    id SERIAL PRIMARY KEY,
    test_id INTEGER REFERENCES test(id),
    student_id INTEGER REFERENCES app_user(id),
    attempt_number INTEGER DEFAULT 1,
    status VARCHAR(20) NOT NULL, -- 'in_progress', 'graded'
    score FLOAT,
    max_score FLOAT,
    percentage FLOAT,
    submitted_at TIMESTAMP,
    auto_graded BOOLEAN DEFAULT FALSE
);

-- Student Answers
CREATE TABLE IF NOT EXISTS student_answer (
    attempt_id INTEGER REFERENCES test_attempt(id),
    question_id INTEGER REFERENCES question_bank(id),
    selected_option_id INTEGER REFERENCES question_option(id),
    is_correct BOOLEAN,
    score FLOAT,
    graded_at TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (attempt_id, question_id)
);

-- SEED DATA --

-- 1. Teacher
INSERT INTO app_user (dni, full_name, email, role)
VALUES ('12345678A', 'Admin Teacher', 'admin@quiz.com', 'teacher')
ON CONFLICT (dni) DO NOTHING;

-- 2. Course
INSERT INTO course (code, name)
VALUES ('2526-45810-A', 'Cloud Digital Leader')
ON CONFLICT (code) DO NOTHING;

-- 3. Questions (Sample)
-- Q1
WITH q AS (
    INSERT INTO question_bank (course_id, question_text, question_type, default_points)
    SELECT id, 'What is the primary benefit of cloud computing?', 'multiple_choice', 0.5
    FROM course WHERE code = '2526-45810-A'
    RETURNING id
)
INSERT INTO question_option (question_id, option_text, is_correct)
SELECT id, 'Cost savings', TRUE FROM q UNION ALL
SELECT id, 'Increased hardware complexity', FALSE FROM q UNION ALL
SELECT id, 'Slower deployment', FALSE FROM q;

-- Q2
WITH q AS (
    INSERT INTO question_bank (course_id, question_text, question_type, default_points)
    SELECT id, 'Which Google Cloud service is used for object storage?', 'multiple_choice', 0.5
    FROM course WHERE code = '2526-45810-A'
    RETURNING id
)
INSERT INTO question_option (question_id, option_text, is_correct)
SELECT id, 'Cloud Storage', TRUE FROM q UNION ALL
SELECT id, 'Compute Engine', FALSE FROM q UNION ALL
SELECT id, 'BigQuery', FALSE FROM q;

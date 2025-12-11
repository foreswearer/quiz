# PPTX Question Upload Tool

## Overview

This tool parses questions from a PowerPoint (PPTX) file and uploads them to the quiz database.

## Features

- Parses questions from PPTX slides
- Automatically detects correct answers (marked in **bold**)
- Supports both single-choice and multiple-choice questions
- Creates database backup before uploading
- Only uploads new questions (checks highest question number in DB)
- Handles slide pattern changes (Q1-66 vs Q67+)

## Files

- `upload_pptx_questions.py` - Main upload script
- `test_pptx_parsing.py` - Test parser without database connection
- `question_pptx/Cloud Digital Leader - Practice questions.pptx` - Source PPTX file

## Usage

### Test Parsing (no database required)

```bash
python test_pptx_parsing.py
```

This will parse the PPTX and show:
- Total questions found
- First 3 and last 3 questions with options
- Question number range

### Upload to Database

**Prerequisites:**
- PostgreSQL database running
- Database credentials configured in `app/config.py`
- Python dependencies installed: `pip install python-pptx`

**Run the upload:**

```bash
python upload_pptx_questions.py
```

The script will:
1. Parse the PPTX file (finds ~124 questions numbered 1-116)
2. Connect to the database
3. Check the highest question number already in the database
4. Create a backup of question_bank and question_option tables
5. Upload only new questions (with number > highest in DB)

## PPTX Format

The PPTX must follow this format:

- **Slide 1**: Title slide (skipped)
- **Slides 2+**: Question pairs
  - Each question appears on TWO consecutive slides
  - One slide has plain text (question only)
  - One slide has the **correct answer(s) in bold**

### Example:

**Slide 2 (Question):**
```
1. What is cloud computing?
Option A
Option B
Option C
Option D
```

**Slide 3 (Answer):**
```
1. What is cloud computing?
Option A
**Option B**  ← Bold = Correct
Option C
Option D
```

## Question Types

- **Single Choice**: Only one option is bold (question_type = 'single_choice')
- **Multiple Choice**: Two or more options are bold (question_type = 'multiple_choice')

## Current Status

- **Total questions in PPTX**: 124 questions (numbered 1-116)
- **Last question in database**: Question 105
- **New questions to upload**: Questions 106-116 (~11 new questions)

## Backup

The script automatically creates a backup file:
- Format: `backup_questions_YYYYMMDD_HHMMSS.sql`
- Contains: All data from `question_bank` and `question_option` tables
- Location: Current directory

## Troubleshooting

### "No questions found"
- Check PPTX file path
- Verify PPTX follows the expected format
- Run test_pptx_parsing.py to debug

### "Could not connect to database"
- Verify PostgreSQL is running
- Check credentials in app/config.py
- Ensure database exists

### "Question has no bold answer"
- Some questions in PPTX don't have bold formatting
- These questions are automatically skipped
- Review the PPTX to add bold formatting if needed

## Notes

- The script only uploads questions with number > highest in database
- Questions are associated with course_id = 1 (default)
- All questions get default_points = 0.5
- Question numbers are extracted from question text (e.g., "105. Question...")

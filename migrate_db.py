import sys
import os

# Add current directory to path so we can import app
sys.path.append(os.getcwd())

from app.db import get_connection


def migrate():
    print("Starting migration...")
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            print("Adding created_by column...")
            cur.execute(
                "ALTER TABLE test ADD COLUMN IF NOT EXISTS created_by INTEGER REFERENCES app_user(id);"
            )

            print("Adding index...")
            cur.execute(
                "CREATE INDEX IF NOT EXISTS idx_test_created_by ON test(created_by);"
            )

            conn.commit()
            print("Migration successful!")
    except Exception as e:
        print(f"Migration failed: {e}")
        conn.rollback()
    finally:
        conn.close()


if __name__ == "__main__":
    migrate()

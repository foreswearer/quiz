# Sync Production Database to Local Windows Machine

This guide walks you through syncing the production database to your local development environment on Windows.

## Prerequisites

- SSH access to `ramiro_rego@quiz.ramiro-rego.com`
- PostgreSQL installed locally on Windows
- Local database user: `quiz_user` / `quiz_user`

## Step 1: Get Fresh Production Dump

SSH to the production server and create a fresh database dump:

```bash
ssh ramiro_rego@quiz.ramiro-rego.com

# Create timestamped dump file
sudo -u postgres pg_dump quiz_platform --no-owner --no-acl > /tmp/quiz_prod_backup_$(date +%Y%m%d_%H%M).sql

# Verify the dump was created
ls -lh /tmp/quiz_prod_backup_*.sql

# Exit SSH
exit
```

## Step 2: Download Dump to Windows

From your Windows machine (PowerShell or Command Prompt):

```bash
cd c:\projects\quiz

# Download the dump file (adjust timestamp in filename)
scp ramiro_rego@quiz.ramiro-rego.com:/tmp/quiz_prod_backup_*.sql db\quiz_prod_backup.sql
```

## Step 3: Recreate Local Database

**IMPORTANT:** This will delete your local database and all data!

```bash
# Drop the existing database
psql -U postgres -c "DROP DATABASE IF EXISTS quiz_platform;"

# Create fresh database
psql -U postgres -c "CREATE DATABASE quiz_platform;"

# Restore from production dump
psql -U postgres -d quiz_platform -f db\quiz_prod_backup.sql
```

## Step 4: Apply Migrations

Apply any pending migrations that aren't in the production dump:

```bash
psql -U postgres -d quiz_platform -f db\migrations\001_add_power_student_role.sql
```

## Step 5: Grant Permissions

Grant permissions to the application's database user:

```bash
psql -U postgres -d quiz_platform -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO quiz_user;"
psql -U postgres -d quiz_platform -c "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO quiz_user;"
psql -U postgres -d quiz_platform -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO quiz_user;"
```

## Step 6: Verify

Verify the database is working:

```bash
# Check tables exist
psql -U postgres -d quiz_platform -c "\dt"

# Check you have data
psql -U postgres -d quiz_platform -c "SELECT COUNT(*) FROM app_user;"

# Verify quiz_user has access
psql -U quiz_user -d quiz_platform -c "SELECT COUNT(*) FROM course;"
```

## Step 7: Start Your App

```bash
python.exe -m uvicorn main:app --reload --port 8000
```

Visit http://127.0.0.1:8000 and verify everything works!

## Quick Sync (If You Already Have Recent Dump)

If `db\quiz_prod_backup.sql` is recent enough, skip Steps 1-2 and start from Step 3.

## Troubleshooting

### Permission Denied Errors

If you see `permission denied for table X`:
```bash
psql -U postgres -d quiz_platform -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO quiz_user;"
psql -U postgres -d quiz_platform -c "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO quiz_user;"
```

### Table Does Not Exist

Your dump file is incomplete or didn't restore properly. Go back to Step 1 and get a fresh dump.

### Migration Already Applied Error

That's fine - it means the migration was already in the production dump. You can ignore this error.

## Notes

- The production database is `quiz_platform` on the server
- Your local database should also be named `quiz_platform`
- All dumps use `--no-owner --no-acl` flags to avoid permission issues
- After syncing, your local data will be identical to production

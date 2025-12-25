# Database Sync Commands - Copy & Paste

## Step 1: Get Fresh Production Dump

```bash
ssh ramiro_rego@quiz.ramiro-rego.com
sudo -u postgres pg_dump quiz_platform --no-owner --no-acl > /tmp/quiz_prod_backup_$(date +%Y%m%d_%H%M).sql
ls -lh /tmp/quiz_prod_backup_*.sql
exit
```

## Step 2: Download to Windows

```bash
cd c:\projects\quiz
scp ramiro_rego@quiz.ramiro-rego.com:/tmp/quiz_prod_backup_*.sql db\quiz_prod_backup.sql
```

## Step 3: Recreate Local Database

```bash
psql -U postgres -c "DROP DATABASE IF EXISTS quiz_platform;"
psql -U postgres -c "CREATE DATABASE quiz_platform;"
psql -U postgres -d quiz_platform -f db\quiz_prod_backup.sql
```

## Step 4: Apply Migrations

```bash
psql -U postgres -d quiz_platform -f db\migrations\001_add_power_student_role.sql
```

## Step 5: Grant Permissions

```bash
psql -U postgres -d quiz_platform -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO quiz_user;"
psql -U postgres -d quiz_platform -c "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO quiz_user;"
psql -U postgres -d quiz_platform -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO quiz_user;"
```

## Step 6: Verify

```bash
psql -U postgres -d quiz_platform -c "\dt"
psql -U postgres -d quiz_platform -c "SELECT COUNT(*) FROM app_user;"
```

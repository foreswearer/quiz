# Quiz Platform Update: Custom Test Names & User Rename

## Files to Download

| File | Destination | Description |
|------|-------------|-------------|
| `schemas.py` | `app/schemas.py` | Replace entire file |
| `api.py` | `app/api.py` | Replace entire file |
| `portal.js` | `static/js/portal.js` | Replace entire file |
| `migration_add_created_by.sql` | Run on server | Database migration |
| `portal_html_changes.html` | Reference for HTML | Manual HTML updates |

---

## Step-by-Step Deployment

### Step 1: Run Database Migration

```bash
# SSH to server
ssh ramiro_rego@quiz.ramiro-rego.com

# Run on STAGING database
sudo -u postgres psql quiz_platform_staging -c "ALTER TABLE test ADD COLUMN IF NOT EXISTS created_by INTEGER REFERENCES app_user(id);"
sudo -u postgres psql quiz_platform_staging -c "CREATE INDEX IF NOT EXISTS idx_test_created_by ON test(created_by);"

# Run on PRODUCTION database
sudo -u postgres psql quiz_platform -c "ALTER TABLE test ADD COLUMN IF NOT EXISTS created_by INTEGER REFERENCES app_user(id);"
sudo -u postgres psql quiz_platform -c "CREATE INDEX IF NOT EXISTS idx_test_created_by ON test(created_by);"
```

### Step 2: Update Local Files

In your local `c:\projects\quiz` directory:

1. Replace `app/schemas.py` with downloaded `schemas.py`
2. Replace `app/api.py` with downloaded `api.py`
3. Replace `static/js/portal.js` with downloaded `portal.js`
4. Update `templates/portal.html` manually (see `portal_html_changes.html`)

### Step 3: Update HTML Template

Edit `templates/portal.html` and add these two elements:

**A) Add test name input (in "Create Random Test" section):**
```html
<label for="test-name">Test Name (optional):</label>
<input type="text" id="test-name" placeholder="My Custom Test" maxlength="100">
```

**B) Add rename button (after View Podium, before teacher-panel):**
```html
<button type="button" id="rename-my-test-btn" class="hidden">✏️ Rename My Test</button>
<div id="rename-info"></div>
```

### Step 4: Deploy to Staging

```bash
cd c:\projects\quiz
git add .
git commit -m "Add custom test names and user rename capability"
git push origin develop
```

### Step 5: Test on Staging

Open http://quiz.ramiro-rego.com:8001 and test:

1. ✅ Create a test WITH custom name → verify name is saved
2. ✅ Create a test WITHOUT name → verify default name is generated  
3. ✅ As student: rename YOUR OWN test → should work
4. ✅ As student: rename SOMEONE ELSE'S test → should show error
5. ✅ As teacher: rename ANY test → should work

### Step 6: Deploy to Production

```bash
git checkout main
git merge develop
git push origin main
git checkout develop
```

---

## What Changed

### Backend (`api.py`)

**`create_random_test` function:**
- Now accepts optional `title` parameter
- Uses custom title if provided, otherwise generates default with user's name
- Stores `created_by` (user ID) in the test record

**`rename_test` function:**
- Teachers can rename ANY test (unchanged)
- Users can now rename tests THEY created
- Uses `user_dni` parameter (also accepts `teacher_dni` for backwards compatibility)

### Frontend (`portal.js`)

- Added `testNameInput` DOM reference
- Updated create handler to send `title` if provided
- Added `renameMyTestBtn` handler for all users
- Shows rename button after login

### Database

- Added `created_by` column to `test` table (references `app_user.id`)
- Added index `idx_test_created_by` for performance

---

## Rollback (if needed)

The database column is nullable, so the code is backwards compatible.
To rollback, simply revert the code changes:

```bash
git revert HEAD
git push origin develop
```

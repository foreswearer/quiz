#!/usr/bin/env bash
set -euo pipefail

# --- STAGING CONFIGURATION ---
APP_DIR="/home/ramiro_rego/quiz-backend-staging"
VENV_DIR="$APP_DIR/venv"
SERVICE_NAME="quiz-backend-staging.service"
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME"
DB_NAME="quiz_platform_staging"
PORT="8001"
# -----------------------------

echo "=== Starting STAGING deployment ==="
echo "Target: $APP_DIR"
echo "Port:   $PORT"
echo "DB:     $DB_NAME"

# 0. Ensure Database Exists
echo "Checking database configuration..."
# Check if DB exists, if not create it.
# We use '|| true' to prevent script failure if the check itself has issues, 
# but rely on createdb to do the work.
if sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'" | grep -q 1; then
    echo "✅ Database $DB_NAME already exists."
else
    echo "Database $DB_NAME not found. Attempting to create..."
    if sudo -u postgres createdb -O quiz_user "$DB_NAME"; then
        echo "✅ Database $DB_NAME created successfully."
    else
        echo "⚠️  Warning: Failed to create database automatically."
        echo "   You may need to run: sudo -u postgres createdb -O quiz_user $DB_NAME"
        exit 1
    fi
fi

# 0.1 Ensure Schema Exists
echo "Checking database schema..."
SCHEMA_EXISTS=$(sudo -u postgres psql -d "$DB_NAME" -tAc "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'app_user');")

if [ "$SCHEMA_EXISTS" = "t" ]; then
    echo "✅ Schema appears to be initialized (app_user table found)."
else
    echo "Schema not found. Initializing..."
    # We need to make sure we are using the schema.sql from the new deployment
    # Use input redirection to avoid permission issues with postgres user reading files in user home
    if sudo -u postgres psql -d "$DB_NAME" < "$APP_DIR/schema.sql"; then
        echo "✅ Schema initialized."
    else
        echo "❌ Failed to initialize schema."
        # Try to print error
        echo "Attempting to debug schema file access:"
        ls -l "$APP_DIR/schema.sql"
        exit 1
    fi
fi

# 0.2 Ensure Permissions
echo "Granting permissions to quiz_user..."
sudo -u postgres psql -d "$DB_NAME" -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO quiz_user;"
sudo -u postgres psql -d "$DB_NAME" -c "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO quiz_user;"

# 0.3 Copy data from production to staging
echo "Copying data from production database..."
PROD_DB="quiz_platform"

# Check if production DB exists
if sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='$PROD_DB'" | grep -q 1; then
    echo "Production database found. Copying data tables..."
    
    # Dump only data (not schema) from production, excluding schema definition
    # We use --data-only to skip CREATE TABLE statements, and --disable-triggers to avoid FK issues
    sudo -u postgres pg_dump "$PROD_DB" \
        --data-only \
        --disable-triggers \
        --exclude-table-data='spatial_ref_sys' \
        | sudo -u postgres psql -d "$DB_NAME" -q
    
    echo "✅ Data copied from production to staging."
else
    echo "⚠️  Production database not found. Staging will use seed data only."
fi

# Ensure app directory exists
if [ ! -d "$APP_DIR" ]; then
    echo "Creating app directory at $APP_DIR..."
    mkdir -p "$APP_DIR"
fi

cd "$APP_DIR"

# 1. Create or reuse virtual environment
echo "Checking virtual environment at $VENV_DIR..."
if [ ! -d "$VENV_DIR" ]; then
  echo "Creating new virtual environment..."
  python3 -m venv "$VENV_DIR"
elif [ ! -f "$VENV_DIR/bin/activate" ]; then
  echo "Virtual environment exists but is broken. Recreating..."
  rm -rf "$VENV_DIR"
  python3 -m venv "$VENV_DIR"
else
  echo "Using existing virtual environment."
fi

# 2. Activate venv and install dependencies
echo "Activating virtual environment..."
# shellcheck disable=SC1090
source "$VENV_DIR/bin/activate"

echo "Upgrading pip..."
python -m pip install --upgrade pip

if [ -f requirements.txt ]; then
  echo "Installing dependencies from requirements.txt..."
  pip install -r requirements.txt
else
  echo "⚠️  Warning: requirements.txt not found!"
fi

# 3. Verify uvicorn is installed
if [ ! -f "$VENV_DIR/bin/uvicorn" ]; then
  echo "❌ ERROR: uvicorn not found in venv! Installing explicitly..."
  pip install uvicorn
fi

echo "✅ Verifying uvicorn path: $(which uvicorn)"

# 4. Create/update systemd service file for STAGING
echo "Creating systemd service file..."
sudo tee "$SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=Cloud Digital Leader Quiz Backend (STAGING)
After=network.target

[Service]
Type=simple
User=ramiro_rego
WorkingDirectory=$APP_DIR
# Run on port 8001 and use staging DB
ExecStart=$VENV_DIR/bin/uvicorn main:app --host 0.0.0.0 --port $PORT
Restart=always
RestartSec=5
Environment="PATH=$VENV_DIR/bin:/usr/local/bin:/usr/bin:/bin"
Environment="PYTHONPATH=$APP_DIR"
Environment="QUIZ_DB_NAME=$DB_NAME"
Environment="QUIZ_DB_USER=quiz_user"
Environment="QUIZ_DB_PASSWORD=C0gum3l0s"
Environment="QUIZ_DB_HOST=localhost"
Environment="QUIZ_DB_PORT=5432"

[Install]
WantedBy=multi-user.target
EOF

echo "✅ Service file created at $SERVICE_FILE"

# 5. Reload systemd and enable service
echo "Reloading systemd daemon..."
sudo systemctl daemon-reload

echo "Enabling service..."
sudo systemctl enable "$SERVICE_NAME"

# 6. Restart service
echo "Restarting $SERVICE_NAME..."
sudo systemctl restart "$SERVICE_NAME"

# 7. Wait a moment and check status
echo "Waiting 3 seconds for service to start..."
sleep 3

echo "Checking service status..."
if sudo systemctl is-active --quiet "$SERVICE_NAME"; then
  echo "✅ Staging Service is running!"
  sudo systemctl status "$SERVICE_NAME" --no-pager
else
  echo "❌ Staging Service failed to start!"
  echo "Recent logs:"
  sudo journalctl -u "$SERVICE_NAME" -n 20 --no-pager
  exit 1
fi

echo "=== Staging Deployment finished successfully ==="

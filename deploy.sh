#!/usr/bin/env bash
set -euo pipefail

APP_DIR="/home/ramiro_rego/quiz-backend"
VENV_DIR="$APP_DIR/venv"
SERVICE_NAME="quiz-backend.service"
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME"

echo "=== Starting deployment ==="
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

# 4. Create/update systemd service file
echo "Creating systemd service file..."
sudo tee "$SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=Cloud Digital Leader Quiz Backend (FastAPI)
After=network.target

[Service]
Type=simple
User=ramiro_rego
WorkingDirectory=$APP_DIR
ExecStart=$VENV_DIR/bin/uvicorn main:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=5
Environment="PATH=$VENV_DIR/bin:/usr/local/bin:/usr/bin:/bin"
Environment="PYTHONPATH=$APP_DIR"

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
  echo "✅ Service is running!"
  sudo systemctl status "$SERVICE_NAME" --no-pager
else
  echo "❌ Service failed to start!"
  echo "Recent logs:"
  sudo journalctl -u "$SERVICE_NAME" -n 20 --no-pager
  exit 1
fi

echo "=== Deployment finished successfully ==="

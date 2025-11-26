#!/usr/bin/env bash
set -euo pipefail

APP_DIR="/home/ramiro_rego/quiz-backend"
VENV_DIR="$APP_DIR/venv"
SERVICE_NAME="quiz-backend.service"  # cambia esto si tu servicio se llama distinto

cd "$APP_DIR"

# 1. Crear o reutilizar el entorno virtual
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

# 2. Activar venv e instalar dependencias
echo "Activating virtual environment..."
# shellcheck disable=SC1090
source "$VENV_DIR/bin/activate"

echo "Upgrading pip..."
python -m pip install --upgrade pip
if [ -f requirements.txt ]; then
  echo "Installing dependencies from requirements.txt..."
  pip install -r requirements.txt
fi

# 3. Reiniciar servicio systemd
sudo systemctl restart "$SERVICE_NAME"

echo "Deployment finished and $SERVICE_NAME restarted."

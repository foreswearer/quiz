#!/usr/bin/env bash
set -euo pipefail

APP_DIR="/home/ramiro_rego/quiz-backend"
VENV_DIR="$APP_DIR/.venv"
SERVICE_NAME="quiz-backend.service"  # cambia esto si tu servicio se llama distinto

cd "$APP_DIR"

# 1. Crear o reutilizar el entorno virtual
if [ ! -d "$VENV_DIR" ]; then
  python3 -m venv "$VENV_DIR"
fi

# 2. Activar venv e instalar dependencias
# shellcheck disable=SC1090
source "$VENV_DIR/bin/activate"

python -m pip install --upgrade pip
if [ -f requirements.txt ]; then
  pip install -r requirements.txt
fi

# 3. Reiniciar servicio systemd
sudo systemctl restart "$SERVICE_NAME"

echo "Deployment finished and $SERVICE_NAME restarted."

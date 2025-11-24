#!/usr/bin/env bash
set -euo pipefail

APP_DIR="/home/ramiro_rego/quiz-backend"
VENV_DIR="$APP_DIR/venv"
LOG_DIR="$APP_DIR/logs"
PID_FILE="$APP_DIR/quiz-backend.pid"

# Command to run your FastAPI app
UVICORN_CMD="$VENV_DIR/bin/uvicorn main:app --host 0.0.0.0 --port 8000"

mkdir -p "$LOG_DIR"

start() {
  # Cool message
  echo "🚀 Starting Cloud Digital Leader quiz backend from: $APP_DIR"

  # Already running?
  if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    echo "ℹ️  Backend is already running with PID $(cat "$PID_FILE")."
    exit 0
  fi

  cd "$APP_DIR"
  # Activate venv
  # shellcheck source=/dev/null
  source "$VENV_DIR/bin/activate"

  # Run in background and capture PID
  nohup $UVICORN_CMD >> "$LOG_DIR/quiz-backend.log" 2>&1 &
  PID=$!

  echo "$PID" > "$PID_FILE"
  echo "✅ Backend started in background with PID $PID"
  echo "   Logs: $LOG_DIR/quiz-backend.log"
}

stop() {
  if [[ ! -f "$PID_FILE" ]]; then
    echo "ℹ️  No PID file found. Backend is probably not running."
    exit 0
  fi

  PID=$(cat "$PID_FILE")

  if kill -0 "$PID" 2>/dev/null; then
    echo "🛑 Stopping backend (PID $PID)…"
    kill "$PID"
    # Optional: wait a bit and force-kill if needed
    for i in {1..10}; do
      if kill -0 "$PID" 2>/dev/null; then
        sleep 1
      else
        break
      fi
    done
    if kill -0 "$PID" 2>/dev/null; then
      echo "⚠️  Process didn’t exit, sending SIGKILL."
      kill -9 "$PID" || true
    fi
    echo "✅ Backend stopped."
  else
    echo "⚪ Process $PID is not running. Cleaning stale PID file."
  fi

  rm -f "$PID_FILE"
}

status() {
  if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    echo "✅ Backend is running with PID $(cat "$PID_FILE")."
  else
    echo "⚪ Backend is NOT running."
  fi
}

restart() {
  echo "🔁 Restarting backend…"
  stop || true
  start
}

case "${1:-}" in
  start)   start ;;
  stop)    stop ;;
  restart) restart ;;
  status)  status ;;
  *)
    echo "Usage: $0 {start|stop|restart|status}"
    exit 1
    ;;
esac


#!/usr/bin/env bash
# Starts, stops or restarts the Python Integration Hub (services/integration) on port 5011.
# Runs uvicorn in the background and, by default, tails its log to this terminal afterward so you
# see output live (Ctrl+C stops watching the log - the hub keeps running). Pass --hidelogs to skip
# that and just return control to the terminal immediately.
#
#   ./scripts/integration.sh start                  start, then tail the log (default)
#   ./scripts/integration.sh start --hidelogs        start, don't tail the log
#   ./scripts/integration.sh start --install         force a fresh pip install first, then start (tails log)
#   ./scripts/integration.sh start --install --hidelogs   same, without tailing
#   ./scripts/integration.sh stop                    stop it
#   ./scripts/integration.sh restart                 stop -> wait 5s -> start -> tail log
#   ./scripts/integration.sh restart --hidelogs       stop -> wait 5s -> start, no tail
#   ./scripts/integration.sh restart --install [--hidelogs]
#   ./scripts/integration.sh status                  check /health
#
# Logs: ./logs/integration/dd-MM-yyyy.log (one file per day, written by the app)
#       ./logs/integration/console.log  (raw stdout/stderr - startup errors before logging is set up)
# PID:  ./.pids/integration.pid
set -euo pipefail
cd "$(dirname "$0")/.."

HUB_DIR="services/integration"
HUB_PORT=5011
mkdir -p logs/integration .pids

# ------------------------------------------------------------------------------------------------ stop

do_stop() {
  echo "== Stopping Integration Hub =="
  local pidfile=".pids/integration.pid"
  if [ -f "$pidfile" ]; then
    local pid; pid=$(cat "$pidfile")
    if kill "$pid" 2>/dev/null; then echo "  stopped integration (pid $pid)"; else echo "  integration (pid $pid) was not running"; fi
    rm -f "$pidfile"
  else
    echo "  no pid file"
  fi
  local port_pid; port_pid=$(netstat -ano 2>/dev/null | grep ":$HUB_PORT " | grep LISTENING | awk '{print $NF}' | head -1 || true)
  if [ -n "$port_pid" ]; then
    echo "  killing PID $port_pid still listening on port $HUB_PORT"
    taskkill //PID "$port_pid" //F >/dev/null 2>&1 || true
  fi
}

# ------------------------------------------------------------------------------------------------ start

do_start() {
  local force_install=$1 hide_logs=$2

  command -v python >/dev/null 2>&1 || { echo "python not found - install Python 3.11+ and reopen Git Bash"; exit 1; }

  if [ ! -f "$HUB_DIR/.env" ]; then
    echo "$HUB_DIR/.env not found. Create it first (settings are listed in $HUB_DIR/app/config.py),"
    echo "or restore the saved copy:  ./config_files/copy_config_files_to_app.sh"
    exit 1
  fi

  echo "== Starting Integration Hub =="
  (
    cd "$HUB_DIR"

    if [ ! -d .venv ]; then
      echo "  creating virtual environment..."
      python -m venv .venv
    fi
    if [ -f .venv/Scripts/activate ]; then source .venv/Scripts/activate; else source .venv/bin/activate; fi
    echo "  python: $(python --version), venv: $VIRTUAL_ENV"

    if [ "$force_install" = "install" ] || ! python -c "import fastapi" >/dev/null 2>&1; then
      echo "  installing dependencies..."
      pip install -q -r requirements.txt
    fi

    set -a; source .env; set +a
    echo "  RABBITMQ_URL=$RABBITMQ_URL"
    echo "  DATABASE_URL=$DATABASE_URL"

    nohup uvicorn app.main:app --port "$HUB_PORT" > "../../logs/integration/console.log" 2>&1 &
    echo $! > "../../.pids/integration.pid"
  )
  echo "  started integration (pid $(cat .pids/integration.pid)) -> port $HUB_PORT"
  echo "Docs: http://localhost:$HUB_PORT/docs"

  if [ "$hide_logs" = "hide" ]; then
    echo "Logs hidden (--hidelogs). Watch later with: tail -F logs/integration/\$(date +%d-%m-%Y).log"
    return
  fi

  local today_log="logs/integration/$(date +%d-%m-%Y).log"
  echo "Tailing $today_log - Ctrl+C stops watching (the hub keeps running in the background)."
  echo
  sleep 1   # give uvicorn a moment to write its first lines before we start tailing
  tail -F "$today_log"
}

# ------------------------------------------------------------------------------------------------ status

do_status() {
  echo "== Integration Hub =="
  local code; code=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$HUB_PORT/health" 2>/dev/null || echo "000")
  if [ "$code" = "200" ]; then
    echo "  integration (port $HUB_PORT): UP"
    curl -s "http://localhost:$HUB_PORT/health"
    echo
  else
    echo "  integration (port $HUB_PORT): NOT RESPONDING (HTTP $code)"
  fi
}

# ------------------------------------------------------------------------------------------------ main

CMD="${1:-}"
shift || true

INSTALL_MODE="skip"
HIDE_LOGS="show"
for arg in "$@"; do
  case "$arg" in
    --install) INSTALL_MODE="install" ;;
    --hidelogs) HIDE_LOGS="hide" ;;
  esac
done

case "$CMD" in
  start)
    do_start "$INSTALL_MODE" "$HIDE_LOGS"
    ;;
  stop)
    do_stop
    ;;
  restart)
    do_stop
    echo
    echo "Waiting 5s before starting..."
    sleep 5
    echo
    do_start "$INSTALL_MODE" "$HIDE_LOGS"
    ;;
  status)
    do_status
    ;;
  *)
    echo "Usage: $0 {start|stop|restart|status} [--install] [--hidelogs]"
    exit 1
    ;;
esac
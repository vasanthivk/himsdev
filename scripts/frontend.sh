#!/usr/bin/env bash
# Starts, stops or restarts all five Next.js frontend zones: shell (3000), patient-engagement-frontend
# (3001), clinical-care-frontend (3002), diagnostics-frontend (3003), revenue-finance-frontend (3006).
#
#   ./scripts/frontend.sh start              install deps (if missing) + start everything
#   ./scripts/frontend.sh start --install    force a fresh npm install first, then start
#   ./scripts/frontend.sh stop               stop everything
#   ./scripts/frontend.sh restart            stop -> wait 5s -> start
#   ./scripts/frontend.sh restart --install  stop -> wait 5s -> npm install -> start
#   ./scripts/frontend.sh status             show what's currently running
#
# Logs: ./logs/<zone>.log     PIDs: ./.pids/<zone>.pid
set -euo pipefail
cd "$(dirname "$0")/.."

declare -A PORTS=( [shell]=3000 [patient-engagement-frontend]=3001 [clinical-care-frontend]=3002 [diagnostics-frontend]=3003 [revenue-finance-frontend]=3006 )
ZONES=(shell patient-engagement-frontend clinical-care-frontend diagnostics-frontend revenue-finance-frontend)
mkdir -p logs .pids

# ------------------------------------------------------------------------------------------------ helpers

kill_pidfile() {
  local name=$1 pidfile=".pids/${1}.pid"
  if [ -f "$pidfile" ]; then
    local pid; pid=$(cat "$pidfile")
    if kill "$pid" 2>/dev/null; then echo "  stopped $name (pid $pid)"; else echo "  $name (pid $pid) was not running"; fi
    rm -f "$pidfile"
  else
    echo "  $name: no pid file"
  fi
}

kill_port() {
  local port=$1
  local pid; pid=$(netstat -ano 2>/dev/null | grep ":$port " | grep LISTENING | awk '{print $NF}' | head -1 || true)
  if [ -n "$pid" ]; then
    echo "  killing PID $pid still listening on port $port"
    taskkill //PID "$pid" //F >/dev/null 2>&1 || true
  fi
}

# ------------------------------------------------------------------------------------------------ stop

do_stop() {
  echo "== Stopping frontend zones =="
  for z in "${ZONES[@]}"; do kill_pidfile "$z"; done
  for z in "${ZONES[@]}"; do kill_port "${PORTS[$z]}"; done
}

# ------------------------------------------------------------------------------------------------ start

do_start() {
  local force_install=$1

  command -v node >/dev/null 2>&1 || { echo "node not found - install Node 20 first and reopen Git Bash"; exit 1; }
  command -v npm  >/dev/null 2>&1 || { echo "npm not found - reinstall Node with npm included"; exit 1; }
  echo "node $(node --version), npm $(npm --version)"
  echo

  for z in "${ZONES[@]}"; do
    echo "== frontend/$z (port ${PORTS[$z]}) =="
    (
      cd "frontend/$z"
      if [ "$force_install" = "install" ] || [ ! -d node_modules ]; then
        echo "  installing dependencies..."
        npm install --no-fund --no-audit
      fi
      nohup npm run dev > "../../logs/$z.log" 2>&1 &
      echo $! > "../../.pids/$z.pid"
    )
    echo "  started $z (pid $(cat .pids/$z.pid))"
  done

  echo
  echo "First compile can take 10-30s per zone - watch: tail -f logs/shell.log"
  echo "Open http://localhost:3000"
}

# ------------------------------------------------------------------------------------------------ status

do_status() {
  echo "== Frontend zones =="
  for z in "${ZONES[@]}"; do
    port="${PORTS[$z]}"
    code=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$port" 2>/dev/null || echo "000")
    [ "$code" = "200" ] && echo "  $z (port $port): UP" || echo "  $z (port $port): NOT RESPONDING (HTTP $code)"
  done
}

# ------------------------------------------------------------------------------------------------ main

CMD="${1:-}"
FLAG="${2:-}"
INSTALL_MODE="skip"
[ "$FLAG" = "--install" ] && INSTALL_MODE="install"

case "$CMD" in
  start)
    do_start "$INSTALL_MODE"
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
    do_start "$INSTALL_MODE"
    ;;
  status)
    do_status
    ;;
  *)
    echo "Usage: $0 {start|stop|restart|status} [--install]"
    exit 1
    ;;
esac
#!/usr/bin/env bash
# Starts, stops or restarts the five .NET workflow services: identity-org, patient-access,
# clinical-care, revenue-cycle, laboratory.
#
# For the Python Integration Hub, use ./scripts/integration.sh instead - it's managed separately.
#
#   ./scripts/backend.sh start --build    build all .NET projects, then start everything
#   ./scripts/backend.sh start            start everything, skipping the .NET build (fast)
#   ./scripts/backend.sh stop             stop everything
#   ./scripts/backend.sh restart --build  stop -> wait 5s -> build -> start
#   ./scripts/backend.sh restart          stop -> wait 5s -> start (no build)
#   ./scripts/backend.sh status           check /health on all five services
#
# Logs: ./logs/<service>.log     PIDs: ./.pids/<service>.pid
set -euo pipefail
cd "$(dirname "$0")/.."

DOTNET_SERVICES=(identity-org patient-access clinical-care revenue-cycle laboratory)
ALL_DOTNET_PROJECTS=(identity-org patient-access clinical-care laboratory imaging pharmacy-supply revenue-cycle digital-engagement field-ops hospital-ops comms-docs back-office)
PORTS_BY_SERVICE_DOTNET="identity-org=5010 patient-access=5001 clinical-care=5002 revenue-cycle=5006 laboratory=5003"
mkdir -p logs .pids

# ------------------------------------------------------------------------------------------------ helpers

port_of() { echo "$PORTS_BY_SERVICE_DOTNET" | tr ' ' '\n' | grep "^$1=" | cut -d= -f2; }

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
  echo "== Stopping .NET services =="
  for s in "${DOTNET_SERVICES[@]}"; do kill_pidfile "$s"; done
  for s in "${DOTNET_SERVICES[@]}"; do kill_port "$(port_of "$s")"; kill_port "$(( $(port_of "$s") + 2000 ))"; done
}

# ------------------------------------------------------------------------------------------------ start

do_start() {
  local build=$1   # "build" or "no-build"

  if [ "$build" = "build" ]; then
    echo "== Building .NET projects =="
    dotnet build shared/Hims.Common/Hims.Common.csproj -nologo -v quiet
    for s in "${ALL_DOTNET_PROJECTS[@]}"; do
      csproj=$(ls services/"$s"/Hims.*.csproj 2>/dev/null | head -1)
      [ -z "$csproj" ] && continue
      dotnet build "$csproj" -nologo -v quiet
    done
    echo "Build succeeded."
    echo
  fi

  echo "== Starting .NET services =="
  for s in "${DOTNET_SERVICES[@]}"; do
    (
      cd "services/$s"
      nohup dotnet run --no-build > "../../logs/$s.log" 2>&1 &
      echo $! > "../../.pids/$s.pid"
    )
    echo "  started $s (pid $(cat .pids/$s.pid)) -> port $(port_of "$s")"
  done

  echo
  echo "Swagger: 5010 identity-org, 5001 patient-access, 5002 clinical-care, 5006 revenue-cycle, 5003 laboratory"
  echo "HTTPS:   same services on port + 2000 (7010, 7001, 7002, 7006, 7003) with certs/hims-local.pfx"
  echo "Logs: ./logs/<service>.log"
  echo "(Integration Hub is managed separately: ./scripts/integration.sh start)"
}

# ------------------------------------------------------------------------------------------------ status

do_status() {
  echo "== .NET services =="
  for s in "${DOTNET_SERVICES[@]}"; do
    port=$(port_of "$s")
    code=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$port/health" 2>/dev/null || echo "000")
    [ "$code" = "200" ] && echo "  $s (port $port): UP" || echo "  $s (port $port): NOT RESPONDING"
    code=$(curl -sk -o /dev/null -w "%{http_code}" "https://localhost:$((port + 2000))/health" 2>/dev/null || echo "000")
    [ "$code" = "200" ] && echo "  $s https (port $((port + 2000))): UP" || echo "  $s https (port $((port + 2000))): NOT RESPONDING"
  done
}

# ------------------------------------------------------------------------------------------------ main

CMD="${1:-}"
FLAG="${2:-}"
BUILD_MODE="no-build"
[ "$FLAG" = "--build" ] && BUILD_MODE="build"

case "$CMD" in
  start)
    do_start "$BUILD_MODE"
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
    do_start "$BUILD_MODE"
    ;;
  status)
    do_status
    ;;
  *)
    echo "Usage: $0 {start|stop|restart|status} [--build]"
    exit 1
    ;;
esac
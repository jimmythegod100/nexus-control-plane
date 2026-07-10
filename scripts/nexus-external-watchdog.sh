#!/usr/bin/env bash
# External MCP watchdog — outside podman lifecycle; polls :8001/:8002/:8003 every 60s.
set -euo pipefail

CONTROL_PLANE="$(cd "$(dirname "$0")/.." && pwd)"
LOG="/var/log/nexus-recovery.log"
FALLBACK_LOG="${HOME}/.organized/logs/nexus-recovery.log"
INTERVAL="${NEXUS_WATCHDOG_INTERVAL:-60}"
TIMEOUT_SEC="${NEXUS_WATCHDOG_TIMEOUT:-15}"
COOLDOWN_SEC="${NEXUS_RECOVERY_COOLDOWN:-300}"
LAST_RECOVERY_DIR="${HOME}/.organized/state/nexus-watchdog-recovery"
DOCKER_HOST="${DOCKER_HOST:-unix:///var/folders/rh/5c_p30l11tj7y9jf_ss1hmy80000gn/T/podman/podman-machine-default-api.sock}"
export DOCKER_HOST

mkdir -p "$(dirname "$FALLBACK_LOG")"
if [[ ! -w "$LOG" ]] 2>/dev/null; then
  touch "$FALLBACK_LOG" 2>/dev/null || true
  LOG="$FALLBACK_LOG"
fi

log() { printf '%s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" | tee -a "$LOG"; }

declare -A PORT_SERVICE=(
  [8001]=gemini-mcp
  [8002]=memory-mcp
  [8003]=gh-mcp
)

probe() {
  local port="$1"
  local code body
  body="$(curl -sS -m "$TIMEOUT_SEC" -w '\n%{http_code}' "http://127.0.0.1:${port}/health" 2>/dev/null || echo -e '\n000')"
  code="$(tail -1 <<<"$body")"
  printf '%s' "$code"
}

restart_service() {
  local svc="$1"
  mkdir -p "$LAST_RECOVERY_DIR"
  local marker="${LAST_RECOVERY_DIR}/${svc}"
  local now last=0
  now="$(date +%s)"
  [[ -f "$marker" ]] && last="$(cat "$marker" 2>/dev/null || echo 0)"
  if (( now - last < COOLDOWN_SEC )); then
    log "RECOVERY: skip $svc (cooldown ${COOLDOWN_SEC}s)"
    return 0
  fi
  date +%s >"$marker"
  log "RECOVERY: restarting $svc"
  (cd "$CONTROL_PLANE" && podman compose restart "$svc") >>"$LOG" 2>&1 \
    && log "RECOVERY: $svc restart OK" \
    || log "RECOVERY: $svc restart FAILED"
}

run_once() {
  local port svc code
  for port in 8001 8002 8003; do
    svc="${PORT_SERVICE[$port]}"
    code="$(probe "$port")"
    if [[ "$code" == "000" ]]; then
      log "FAIL: $svc (:$port) timeout>${TIMEOUT_SEC}s"
      restart_service "$svc"
    elif [[ "$code" =~ ^5 ]]; then
      log "FAIL: $svc (:$port) HTTP $code"
      restart_service "$svc"
    else
      log "OK: $svc (:$port) HTTP $code"
    fi
  done
}

case "${1:-loop}" in
  once) run_once ;;
  loop)
    log "=== nexus-external-watchdog START interval=${INTERVAL}s timeout=${TIMEOUT_SEC}s ==="
    while true; do
      run_once
      sleep "$INTERVAL"
    done
    ;;
  *) echo "Usage: $0 {once|loop}" >&2; exit 1 ;;
esac

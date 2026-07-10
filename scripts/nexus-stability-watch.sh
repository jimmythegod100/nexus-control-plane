#!/usr/bin/env bash
# Nexus stability watchdog — control plane health (upload/social-bridge removed 2026-07-02).
set -euo pipefail

NEXUS_ROOT="${HOME}/projects/nexus"
LOG="${NEXUS_ROOT}/logs/nexus-stability-watch.log"
CP_URL="${NEXUS_CONTROL_PLANE_URL:-http://127.0.0.1:8788/health}"

log() { printf '%s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" | tee -a "$LOG"; }

main() {
  log "=== nexus-stability-watch START ==="
  if curl -sf --max-time 3 "$CP_URL" >/dev/null 2>&1; then
    log "OK control-plane health"
  else
    log "WARN control-plane unreachable at $CP_URL"
  fi
  log "=== nexus-stability-watch DONE ==="
}

main "$@"

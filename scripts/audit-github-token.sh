#!/usr/bin/env bash
# Audit GitHub token integrity and scope minimization for nexus-gh-mcp.
set -euo pipefail

CONTROL_PLANE="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="${CONTROL_PLANE}/.env"
LOG="${HOME}/.organized/logs/nexus-github-audit.log"
REQUIRED_SCOPES=(repo)
RECOMMENDED_SCOPES=(repo read:user)
OVERPRIVILEGED=(
  admin:enterprise admin:org delete_repo admin:org_hook
  admin:public_key admin:repo_hook admin:ssh_signing_key
)

mkdir -p "$(dirname "$LOG")"

log() { printf '%s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" | tee -a "$LOG"; }

log "=== GitHub token audit START ==="

if ! command -v gh >/dev/null 2>&1; then
  log "FAIL: gh CLI not installed"
  exit 1
fi

gh auth status 2>&1 | tee -a "$LOG" || true

log "--- API identity ---"
gh api user -q '{login: .login, id: .id, type: .type}' 2>&1 | tee -a "$LOG" || true

log "--- Rate limit ---"
gh api rate_limit -q '.resources.core | {limit, remaining, reset}' 2>&1 | tee -a "$LOG" || true

log "--- Scope analysis (nexus-gh-mcp minimum: repo) ---"
scopes_line="$(gh auth status 2>&1 | rg "Token scopes" || true)"
log "$scopes_line"

missing=()
for scope in "${REQUIRED_SCOPES[@]}"; do
  if ! grep -q "$scope" <<<"$scopes_line"; then
    missing+=("$scope")
  fi
done

if ((${#missing[@]})); then
  log "FAIL: Missing required scopes: ${missing[*]}"
else
  log "OK: Required scopes present"
fi

for scope in "${OVERPRIVILEGED[@]}"; do
  if grep -q "$scope" <<<"$scopes_line"; then
    log "WARN: Overprivileged scope detected: $scope — rotate to fine-grained PAT (repo only)"
  fi
done

if [[ -f "$ENV_FILE" ]] && grep -q '^GITHUB_TOKEN=' "$ENV_FILE"; then
  log "OK: GITHUB_TOKEN present in .env"
else
  log "WARN: GITHUB_TOKEN missing from .env"
fi

log "=== GitHub token audit DONE ==="

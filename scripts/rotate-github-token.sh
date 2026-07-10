#!/usr/bin/env bash
# Sync GITHUB_TOKEN from gh keyring into .env; enforce 30-day rotation policy.
set -euo pipefail

CONTROL_PLANE="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="${CONTROL_PLANE}/.env"
META_FILE="${CONTROL_PLANE}/.github-token-meta"
LOG="${HOME}/.organized/logs/nexus-github-rotate.log"
ROTATION_DAYS="${NEXUS_GITHUB_TOKEN_ROTATION_DAYS:-30}"
DOCKER_HOST="${DOCKER_HOST:-unix:///var/folders/rh/5c_p30l11tj7y9jf_ss1hmy80000gn/T/podman/podman-machine-default-api.sock}"
export DOCKER_HOST

mkdir -p "$(dirname "$LOG")"

log() { printf '%s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" | tee -a "$LOG"; }

now_epoch() { date +%s; }

read_rotated_at() {
  if [[ -f "$META_FILE" ]]; then
    python3 -c "import json; print(json.load(open('$META_FILE')).get('rotated_at_epoch', 0))" 2>/dev/null || echo 0
  else
    echo 0
  fi
}

write_meta() {
  local token_hash
  token_hash="$(printf '%s' "$1" | shasum -a 256 | awk '{print $1}')"
  cat >"$META_FILE" <<EOF
{
  "rotated_at_epoch": $(now_epoch),
  "rotated_at_iso": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "token_sha256": "${token_hash}",
  "rotation_policy_days": ${ROTATION_DAYS}
}
EOF
}

update_env_token() {
  local token="$1"
  python3 - "$ENV_FILE" "$token" <<'PY'
import re, sys
from pathlib import Path
path = Path(sys.argv[1])
token = sys.argv[2]
text = path.read_text() if path.exists() else ""
if re.search(r"^GITHUB_TOKEN=", text, re.M):
    text = re.sub(r"^GITHUB_TOKEN=.*$", f"GITHUB_TOKEN={token}", text, flags=re.M)
else:
    text = text.rstrip() + f"\nGITHUB_TOKEN={token}\n"
path.write_text(text)
PY
}

log "=== GitHub token rotation policy check ==="

if ! command -v gh >/dev/null 2>&1; then
  log "FAIL: gh CLI unavailable"
  exit 1
fi

token="$(gh auth token 2>/dev/null || true)"
if [[ -z "$token" ]]; then
  log "FAIL: No gh auth token — run: gh auth login -s repo,read:user"
  exit 1
fi

last="$(read_rotated_at)"
now="$(now_epoch)"
age_days=$(( (now - last) / 86400 ))

if [[ "$last" -eq 0 ]]; then
  log "INFO: First rotation metadata write"
elif (( age_days >= ROTATION_DAYS )); then
  log "ALERT: Token age ${age_days}d exceeds ${ROTATION_DAYS}d policy — regenerate fine-grained PAT:"
  log "  gh auth login -h github.com -s repo,read:user"
  log "  Then re-run this script"
else
  log "INFO: Token age ${age_days}d / ${ROTATION_DAYS}d policy OK"
fi

update_env_token "$token"
write_meta "$token"
log "OK: Synced GITHUB_TOKEN to .env (hash recorded in .github-token-meta)"

if command -v podman >/dev/null 2>&1; then
  (cd "$CONTROL_PLANE" && podman compose up -d --no-deps gh-mcp) >>"$LOG" 2>&1 \
    && log "OK: Rolling restart gh-mcp" \
    || log "WARN: gh-mcp restart failed"
fi

log "=== Rotation sync DONE ==="

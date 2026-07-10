#!/usr/bin/env bash
# Migrate to least-privilege GitHub token (fine-grained PAT or classic repo+read:user).
# Fine-grained PATs must be created at https://github.com/settings/personal-access-tokens
# then: echo "$NEW_TOKEN" | bash scripts/rotate-github-fine-grained.sh
set -euo pipefail

CONTROL_PLANE="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="${CONTROL_PLANE}/.env"
LOG="${HOME}/.organized/logs/nexus-github-fine-grained.log"

mkdir -p "$(dirname "$LOG")"
log() { printf '%s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" | tee -a "$LOG"; }

log "=== Fine-grained / least-privilege GitHub rotation ==="

if [[ -t 0 ]] && [[ ! -f "${1:-}" ]]; then
  log "INFO: Create token at https://github.com/settings/personal-access-tokens"
  log "  Repository access: jimmythegod100/* (or specific nexus repos)"
  log "  Permissions: Contents R/W, Metadata R, Pull requests R/W"
  log "  OR classic: gh auth login -h github.com -s repo,read:user -p https --skip-ssh-key -w"
  log "Paste new token on stdin, then press Ctrl-D"
fi

token=""
if [[ -n "${1:-}" && -f "$1" ]]; then
  token="$(<"$1")"
else
  token="$(cat)"
fi
token="${token//$'\n'/}"
token="${token//$'\r'/}"
[[ -n "$token" ]] || { log "FAIL: empty token"; exit 1; }

printf '%s' "$token" | gh auth login --with-token
log "OK: gh auth login --with-token"

gh auth status 2>&1 | tee -a "$LOG"
login="$(gh api user -q .login 2>/dev/null || echo unknown)"
log "Identity verified: $login"

python3 - "$ENV_FILE" "$token" <<'PY'
import re, sys
from pathlib import Path
path, token = Path(sys.argv[1]), sys.argv[2]
text = path.read_text()
text = re.sub(r'^GITHUB_TOKEN=.*$', f'GITHUB_TOKEN={token}', text, flags=re.M) if re.search(r'^GITHUB_TOKEN=', text, re.M) else text.rstrip() + f'\nGITHUB_TOKEN={token}\n'
path.write_text(text)
PY
log "OK: .env updated"

export DOCKER_HOST="${DOCKER_HOST:-unix:///var/folders/rh/5c_p30l11tj7y9jf_ss1hmy80000gn/T/podman/podman-machine-default-api.sock}"
(cd "$CONTROL_PLANE" && podman compose up -d --no-deps gh-mcp) >>"$LOG" 2>&1 && log "OK: gh-mcp restarted"

curl -sf http://localhost:8003/health | tee -a "$LOG"
log "=== Rotation complete ==="

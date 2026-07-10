#!/usr/bin/env bash
# 50-request burst load test against nexus-gemini-mcp :8001/health
set -euo pipefail

TARGET="${NEXUS_GEMINI_LOAD_URL:-http://127.0.0.1:8001/health}"
BURST="${NEXUS_GEMINI_BURST:-50}"
TIMEOUT="${NEXUS_GEMINI_TIMEOUT:-10}"
LOG="${HOME}/.organized/logs/nexus-gemini-loadtest.log"

mkdir -p "$(dirname "$LOG")"

log() { printf '%s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" | tee -a "$LOG"; }

log "=== Gemini MCP load test burst=$BURST target=$TARGET ==="
start_ms=$(( $(date +%s) * 1000 ))

ok=0
fail=0
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

for i in $(seq 1 "$BURST"); do
  (
    code="$(curl -sS -m "$TIMEOUT" -o /dev/null -w '%{http_code}' "$TARGET" 2>/dev/null || echo 000)"
    echo "$code" >"$tmpdir/$i.code"
  ) &
done
wait

for i in $(seq 1 "$BURST"); do
  code="$(cat "$tmpdir/$i.code")"
  if [[ "$code" == "200" ]]; then
    ok=$((ok + 1))
  else
    fail=$((fail + 1))
  fi
done

end_ms=$(( $(date +%s) * 1000 ))
elapsed=$(( end_ms - start_ms ))

log "RESULT: ok=$ok fail=$fail elapsed_ms=$elapsed avg_ms=$(( elapsed / BURST ))"

if (( fail > 0 )); then
  log "FAIL: $fail/$BURST requests did not return 200"
  exit 1
fi

log "PASS: $BURST/$BURST concurrent health checks succeeded"
# Sample post-burst health body
curl -sS "$TARGET" | tee -a "$LOG"
echo "" | tee -a "$LOG"

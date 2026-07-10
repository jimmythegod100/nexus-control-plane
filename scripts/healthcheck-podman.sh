#!/usr/bin/env bash
# Podman-aware container status probe for macOS/Darwin.
# Uses DOCKER_HOST when pointing at the Podman machine API socket.
set -euo pipefail

export DOCKER_HOST="${DOCKER_HOST:-unix:///var/folders/rh/5c_p30l11tj7y9jf_ss1hmy80000gn/T/podman/podman-machine-default-api.sock}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}/.."

if command -v podman >/dev/null 2>&1; then
  COMPOSE=(podman compose)
elif command -v docker >/dev/null 2>&1; then
  COMPOSE=(docker compose)
else
  echo "ERROR: Neither podman nor docker available" >&2
  exit 1
fi

echo "NEXUS Control Plane — Podman health probe"
echo "DOCKER_HOST=${DOCKER_HOST}"
echo ""

statuses="$("${COMPOSE[@]}" ps --format json 2>/dev/null | jq -s -r '.[].State' 2>/dev/null || true)"

if [[ -z "${statuses}" ]]; then
  echo "WARN: No compose services running or ps output empty"
  exit 1
fi

echo "Container states:"
while IFS= read -r state; do
  [[ -n "${state}" ]] && echo "  ${state}"
done <<< "${statuses}"

if grep -qv '^running$' <<< "${statuses}"; then
  echo ""
  echo "FAIL: One or more containers are not running"
  "${COMPOSE[@]}" ps
  exit 1
fi

echo ""
echo "PostgreSQL:"
if "${COMPOSE[@]}" exec -T postgres pg_isready -U nexus_user -d nexus >/dev/null 2>&1; then
  echo "  OK"
else
  echo "  FAIL"
  exit 1
fi

echo "Redis:"
if "${COMPOSE[@]}" exec -T redis redis-cli ping 2>/dev/null | grep -q PONG; then
  echo "  OK"
else
  echo "  FAIL"
  exit 1
fi

echo ""
echo "All services healthy"

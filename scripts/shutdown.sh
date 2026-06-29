#!/bin/bash
set -euo pipefail

echo "Stopping NEXUS Control Plane..."

COMPOSE="docker-compose"
if ! command -v docker-compose >/dev/null 2>&1; then
  COMPOSE="docker compose"
fi

$COMPOSE down
echo "NEXUS Control Plane stopped"

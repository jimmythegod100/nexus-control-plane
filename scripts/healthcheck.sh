#!/bin/bash
set -euo pipefail

echo "NEXUS Control Plane — health check"
echo "==================================="

if ! command -v docker-compose >/dev/null 2>&1 && ! command -v docker >/dev/null 2>&1; then
  echo "WARN: Docker not available in this environment"
  exit 0
fi

COMPOSE="docker-compose"
if ! command -v docker-compose >/dev/null 2>&1; then
  COMPOSE="docker compose"
fi

$COMPOSE ps

echo ""
echo "PostgreSQL:"
if $COMPOSE exec -T postgres pg_isready -U nexus_user -d nexus >/dev/null 2>&1; then
  echo "  OK"
else
  echo "  FAIL"
  exit 1
fi

echo "Redis:"
if $COMPOSE exec -T redis redis-cli ping 2>/dev/null | grep -q PONG; then
  echo "  OK"
else
  echo "  FAIL"
  exit 1
fi

echo ""
echo "All services healthy"

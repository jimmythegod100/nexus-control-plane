#!/usr/bin/env bash
set -euo pipefail
# Requires GH_TOKEN with repo scope (Cloud Agent env var or: export GH_TOKEN=ghp_...)
: "${GH_TOKEN:?Set GH_TOKEN to a GitHub PAT with repo scope}"
export GH_TOKEN
gh repo create jimmythegod100/nexus-control-plane \
  --public \
  --description "NEXUS control plane - PostgreSQL + Redis + MCP discovery" \
  --source=. \
  --remote=origin \
  --push
echo "Repository created: https://github.com/jimmythegod100/nexus-control-plane"

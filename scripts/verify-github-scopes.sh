#!/usr/bin/env bash
# Fail if gh token still carries admin:* or delete_repo scopes.
set -euo pipefail
scopes="$(gh auth status 2>&1 | rg "Token scopes" || true)"
if echo "$scopes" | rg -q "admin:|delete_repo"; then
  echo "ABORT: GitHub token is overprivileged:" >&2
  echo "$scopes" >&2
  echo "Provide least-privilege token:" >&2
  echo "  echo \"\$NEW_TOKEN\" | bash ~/projects/nexus/nexus-control-plane/scripts/rotate-github-fine-grained.sh" >&2
  exit 1
fi
gh api user -q .login
echo "OK: least-privilege scope verified"

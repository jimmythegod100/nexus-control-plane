#!/usr/bin/env bash
# Verify GitHub authentication using GH_TOKEN from environment only.
set -euo pipefail

: "${GH_TOKEN:?GH_TOKEN is not set}"

export GH_TOKEN

if ! login=$(gh api user --jq .login 2>/dev/null); then
  echo "AUTH_FAIL: GitHub API rejected credentials"
  exit 1
fi

if [ "$login" != "jimmythegod100" ]; then
  echo "AUTH_FAIL: unexpected account ($login)"
  exit 1
fi

if ! gh repo view jimmythegod100/nexus-control-plane --json name --jq .name >/dev/null 2>&1; then
  echo "AUTH_FAIL: cannot access nexus-control-plane"
  exit 1
fi

echo "AUTH_OK: verified as $login with repo access"

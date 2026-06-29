# NEXUS Control Plane Setup

## Prerequisites

- Docker and Docker Compose
- GitHub CLI (`gh`) for repo operations
- `GH_TOKEN` with `repo` scope (Cloud Agent env var)

## Quick Start

```bash
git clone https://github.com/jimmythegod100/nexus-control-plane.git
cd nexus-control-plane
cp .env.example .env
# Edit .env with API keys
make up
make health
```

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/startup.sh` | Start services with health waits |
| `scripts/shutdown.sh` | Stop all services |
| `scripts/healthcheck.sh` | Verify PostgreSQL + Redis |
| `scripts/verify-github-auth.sh` | Silent GitHub auth check |

## Verify GitHub Auth

```bash
export GH_TOKEN=...   # from Cloud Agent secrets
./scripts/verify-github-auth.sh
```

## Next Steps

1. Start `nexus-gemini-mcp` (port 8001)
2. Start `nexus-memory-mcp` (port 8002)
3. Start `nexus-gh-mcp` (port 8003)
4. Start `nexus-video-service` (port 8080)

# NEXUS Control Plane Architecture

## Overview

The control plane provides shared infrastructure for all NEXUS microservices:

- **PostgreSQL 15** — job metadata, audit logs, MCP server registry
- **Redis 7** — job queue and caching layer

## Service Topology

```
Cursor Agents
     │
     ├── nexus-gemini-mcp   :8001  (video generation)
     ├── nexus-memory-mcp   :8002  (persistence)
     ├── nexus-gh-mcp       :8003  (GitHub automation)
     └── nexus-video-service :8080 (orchestrator)
            │
            ▼
   nexus-control-plane (docker-compose)
     ├── postgres:5432
     └── redis:6379
```

## Database Schema

Initialized via `db/init.sql`:

- `jobs` — video generation job records
- `job_metrics` — per-job metrics
- `audit_log` — service audit trail
- `mcp_servers` — MCP discovery registry
- `github_repos` — tracked repository metadata

## Agent Configuration

- `.cursor/rules.md` — NEXUS coding standards and service registry
- `.cursor/compose.yml` — agent definitions and MCP server bindings

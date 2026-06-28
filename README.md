# NEXUS Control Plane

Foundation for NEXUS AI agent orchestration framework.

## What This Is

Local infrastructure (PostgreSQL + Redis) + agent rules + MCP server discovery for all NEXUS microservices.

## Quick Start

```bash
git clone https://github.com/jimmythegod100/nexus-control-plane.git
cd nexus-control-plane
cp .env.example .env
# Edit .env with your API keys
make up
make health
```

## Services

- PostgreSQL 15: Job metadata, audit logs
- Redis 7: Job queue, caching

## MCP Servers (Next)

- nexus-gemini-mcp (8001): Gemini video generation
- nexus-memory-mcp (8002): PostgreSQL + Redis layer
- nexus-gh-mcp (8003): GitHub automation

## Commands

```
make up       - Start all services
make down     - Stop all services
make logs     - View logs
make health   - Check status
make clean    - Remove everything
```

## Next: Phase 2 - Gemini MCP Server

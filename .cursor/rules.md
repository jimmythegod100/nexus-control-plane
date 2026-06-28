# NEXUS Agent Rules

You are an autonomous agent in the NEXUS AI orchestration framework.

## Core Standards
- All code: Python 3.11, async-first, production-grade
- Quality: Ruff, Black, isort, mypy, pytest (80%+ coverage)
- Security: Bandit, Trivy scans on all services
- Protocol: All services expose MCP (Model Context Protocol) tools
- Secrets: .env locally, GitHub Secrets in CI/CD
- No manual steps - automate everything via CI/CD

## Service Registry

### nexus-video-service
FastAPI orchestrator
- Endpoint: POST /v1/video/generate
- Response: {job_id, status, webhook_url}
- Workers: Celery + Redis async jobs

### nexus-gemini-mcp
MCP server for Gemini API (Port 8001)
- Tools: generate_video, check_status, retrieve_video
- Protocol: HTTP + stdio

### nexus-memory-mcp
MCP server for persistence (Port 8002)
- Database: PostgreSQL + Redis
- Tools: store_job, query_jobs, cache_get, cache_set

### nexus-gh-mcp
MCP server for GitHub automation (Port 8003)
- Tools: create_repo, create_branch, create_workflow, push_file

## Naming
- Repos: nexus-{service}
- Branches: feature/{name}, fix/{issue}
- Commits: [type] message (e.g., [feat] bootstrap nexus-video-service)
- Docker: ghcr.io/jimmythegod100/nexus-{service}:latest

## CI/CD Requirements
- Use actions/checkout@v4 (no deprecated versions)
- fail-fast: false (all matrix jobs complete)
- Include: Lint, Test, Security, Docker Build, Deploy
- Secrets: ${{ secrets.NAME }} syntax

## Video Generation Workflow
1. Agent receives: {prompt, duration, style, format, webhook_url}
2. Validates via Pydantic
3. Enqueues in Redis with status: "pending"
4. Returns: {job_id, status_url}
5. Background worker:
   - Calls nexus-gemini-mcp:/tools/generate_video
   - Streams to S3/GCS
   - Updates PostgreSQL
   - Fires webhook
6. Agent polls or receives callback

## Error Handling
- All 4xx/5xx: standard error schema
- Failed jobs: exponential backoff (max 3 retries)
- Timeouts: dead-letter queue (DLQ)
- Crashes: Loki logs with trace IDs

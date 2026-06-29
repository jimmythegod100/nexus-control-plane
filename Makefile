.PHONY: help up down restart logs health init clean verify-auth

help:
	@echo "NEXUS Control Plane"
	@echo "  make up            Start services"
	@echo "  make down          Stop services"
	@echo "  make restart       Restart services"
	@echo "  make logs          Tail logs"
	@echo "  make health        Run health checks"
	@echo "  make init          Initialize database schema"
	@echo "  make verify-auth   Verify GitHub GH_TOKEN"
	@echo "  make clean         Remove volumes"

up:
	@bash scripts/startup.sh

down:
	@bash scripts/shutdown.sh

restart: down up

logs:
	docker-compose logs -f

health:
	@bash scripts/healthcheck.sh

init:
	@echo "Initializing database..."
	@docker-compose exec -T postgres psql -U nexus_user -d nexus -f /docker-entrypoint-initdb.d/init.sql

verify-auth:
	@bash scripts/verify-github-auth.sh

clean:
	docker-compose down -v

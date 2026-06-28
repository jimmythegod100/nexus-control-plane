.PHONY: help up down logs health init clean

help:
	@echo "NEXUS Control Plane"
	@echo "  make up          Start services"
	@echo "  make down        Stop services"
	@echo "  make logs        Tail logs"
	@echo "  make health      Check status"
	@echo "  make clean       Remove volumes"

up:
	docker-compose up -d
	@echo "Waiting for PostgreSQL..."
	@until docker-compose exec -T postgres pg_isready -U nexus_user -d nexus > /dev/null 2>&1; do sleep 1; done
	@echo "✓ PostgreSQL ready"
	@echo "Waiting for Redis..."
	@until docker-compose exec -T redis redis-cli ping > /dev/null 2>&1; do sleep 1; done
	@echo "✓ Redis ready"
	@echo "✓ NEXUS Control Plane running"

down:
	docker-compose down

logs:
	docker-compose logs -f

health:
	docker-compose ps

clean:
	docker-compose down -v

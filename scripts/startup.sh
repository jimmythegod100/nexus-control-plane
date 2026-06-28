#!/bin/bash
set -e

echo "🚀 Starting NEXUS Control Plane..."

if [ ! -f .env ]; then
    echo "❌ .env file not found"
    exit 1
fi

source .env

echo "📦 Starting Docker Compose..."
docker-compose up -d

echo "⏳ Waiting for PostgreSQL..."
until docker-compose exec -T postgres pg_isready -U nexus_user -d nexus > /dev/null 2>&1; do
    sleep 1
done
echo "✅ PostgreSQL ready"

echo "⏳ Waiting for Redis..."
until docker-compose exec -T redis redis-cli ping > /dev/null 2>&1; do
    sleep 1
done
echo "✅ Redis ready"

echo "✅ NEXUS Control Plane is running!"

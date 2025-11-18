.PHONY: help start stop restart logs status health clean network build build-start push

help:
	@echo "OTEL Collector Management"
	@echo ""
	@echo "Usage:"
	@echo "  make start      - Start the OTEL collector (using official image)"
	@echo "  make stop       - Stop the OTEL collector"
	@echo "  make restart    - Restart the OTEL collector"
	@echo "  make logs       - View collector logs"
	@echo "  make status     - Check collector status"
	@echo "  make health     - Check collector health"
	@echo "  make clean      - Stop and remove container"
	@echo "  make network    - Create otel-network if it doesn't exist"
	@echo ""
	@echo "Build Commands:"
	@echo "  make build      - Build custom Docker image"
	@echo "  make build-start - Build and start with custom image"
	@echo "  make push       - Push custom image to registry"
	@echo ""

start:
	@echo "Starting OTEL collector..."
	docker-compose up -d
	@echo "✅ OTEL collector started"
	@echo "Endpoints:"
	@echo "  - OTLP gRPC: localhost:4317"
	@echo "  - OTLP HTTP: localhost:4318"
	@echo "  - Health: http://localhost:13133"

stop:
	@echo "Stopping OTEL collector..."
	docker-compose stop
	@echo "✅ OTEL collector stopped"

restart:
	@echo "Restarting OTEL collector..."
	docker-compose restart
	@echo "✅ OTEL collector restarted"

logs:
	docker-compose logs -f

status:
	docker-compose ps

health:
	@echo "Checking OTEL collector health..."
	@curl -s http://localhost:13133/ && echo "✅ Collector is healthy" || echo "❌ Collector is not responding"

clean:
	@echo "Stopping and removing OTEL collector..."
	docker-compose down
	@echo "✅ OTEL collector removed"

network:
	@echo "Creating otel-network..."
	@docker network create otel-network 2>/dev/null && echo "✅ Network created" || echo "ℹ️  Network already exists"

build:
	@echo "Building custom OTEL collector image..."
	docker build -t tyklink/otel-collector:latest .
	@echo "✅ Image built: tyklink/otel-collector:latest"

build-start:
	@echo "Building and starting custom OTEL collector..."
	docker-compose -f docker-compose.build.yml up -d --build
	@echo "✅ Custom OTEL collector started"

push:
	@echo "Pushing image to registry..."
	@read -p "Enter registry URL (e.g., docker.io, ghcr.io): " registry; \
	docker tag tyklink/otel-collector:latest $$registry/tyklink/otel-collector:latest; \
	docker push $$registry/tyklink/otel-collector:latest
	@echo "✅ Image pushed"


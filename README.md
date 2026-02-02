# OpenTelemetry Collector Service

Centralized OpenTelemetry Collector for all Tyklink services. Receives traces, metrics, and logs via OTLP protocol and exports to ClickHouse.

## Features

✅ **OTLP Receivers** - gRPC (4317) and HTTP (4318)  
✅ **ClickHouse Export** - Traces, metrics, and logs  
✅ **Auto Schema** - Tables created automatically  
✅ **Health Checks** - Endpoint on port 13133  

## Quick Start

### 1. Configure Environment

```bash
cp env.example .env
```

Edit `.env` with your ClickHouse DSN:

```bash
# For HTTP port (8123/18123):
CLICKHOUSE_DSN=http://default:password@localhost:18123/otel

# For native TCP port (9000):
# CLICKHOUSE_DSN=clickhouse://default:password@localhost:9000/otel
```

### 2. Start the Collector

```bash
docker-compose up -d
```

### 3. Check Status

```bash
docker-compose ps
docker-compose logs -f
curl http://localhost:13133/
```

## Ports

| Port  | Protocol | Description           |
|-------|----------|-----------------------|
| 4317  | gRPC     | OTLP gRPC receiver    |
| 4318  | HTTP     | OTLP HTTP receiver    |
| 13133 | HTTP     | Health check endpoint |

## Network

The collector creates a Docker network named `otel-network` that other services can join.

### Connect Your Services

#### Docker Compose

```yaml
services:
  your-service:
    environment:
      - OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4318
    networks:
      - otel-network

networks:
  otel-network:
    external: true
    name: otel-network
```

#### Host Network

```bash
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318
```

## Configuration

The collector configuration is in `otel-collector-config.yaml`.

### Components

#### Receivers
- **OTLP gRPC**: Port 4317
- **OTLP HTTP**: Port 4318

#### Processors
- **batch**: Batches telemetry data (5s timeout, 10k batch size)

#### Exporters
- **clickhouse**: Exports traces, metrics, and logs with auto schema creation

### ClickHouse Tables

The collector automatically creates these tables:
- `otel_traces` - Distributed traces
- `otel_metrics` - Metrics data
- `otel_logs` - Log entries

Data is retained for 72 hours (configurable via `ttl` setting).

## Services Using This Collector

1. **linktrax-main** - Main application (Nuxt 3)
2. **redirect-trace-service** - Redirect tracing (NestJS)
3. **web-scraper-service** - Web scraping (NestJS)

## Troubleshooting

### Collector Not Starting

```bash
docker-compose logs
```

Common issues:
- Missing `.env` file
- ClickHouse not reachable
- Port conflicts (4317, 4318, 13133)

### Data Not Appearing in ClickHouse

1. Check collector logs:
   ```bash
   docker-compose logs -f
   ```

2. Verify ClickHouse connection:
   ```bash
   clickhouse-client --host localhost --query "SELECT count() FROM otel.otel_traces"
   ```

3. Test OTLP endpoint:
   ```bash
   curl -X POST http://localhost:4318/v1/traces \
     -H "Content-Type: application/json" \
     -d '{"resourceSpans":[]}'
   ```

### Services Can't Connect

```bash
docker network inspect otel-network
```

## Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `CLICKHOUSE_DSN` | ClickHouse connection string | `http://user:pass@host:18123/db` |

**DSN Formats**:
- HTTP: `http://username:password@host:port/database`
- Native: `clickhouse://username:password@host:9000/database`

## Architecture

```
┌─────────────────────┐
│  linktrax-main      │──┐
│  (Nuxt 3)           │  │
└─────────────────────┘  │
                         │
┌─────────────────────┐  │    ┌─────────────────────┐    ┌──────────────────┐
│  redirect-trace     │──┼───>│  OTEL Collector     │───>│  ClickHouse      │
│  (NestJS)           │  │    │  (Docker)           │    │                  │
└─────────────────────┘  │    │                     │    │  - otel_traces   │
                         │    │  Ports:             │    │  - otel_metrics  │
┌─────────────────────┐  │    │  - 4317 (gRPC)     │    │  - otel_logs     │
│  web-scraper        │──┘    │  - 4318 (HTTP)     │    └──────────────────┘
│  (NestJS)           │       └─────────────────────┘
└─────────────────────┘
```

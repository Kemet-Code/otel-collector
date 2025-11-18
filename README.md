# OpenTelemetry Collector Service

Centralized OpenTelemetry Collector for all Tyklink services. Receives traces, metrics, and logs via OTLP protocol and forwards them to Grafana Cloud.

## Features

✅ **OTLP Receivers** - gRPC (4317) and HTTP (4318)  
✅ **Grafana Cloud Export** - Traces, metrics, and logs  
✅ **Resource Detection** - Automatic environment and system metadata  
✅ **Attribute Cleanup** - Removes unnecessary resource attributes  
✅ **Debug Mode** - Console logging for troubleshooting  
✅ **Health Checks** - Endpoint on port 13133  

## Quick Start

### Option A: Using Official Image (Recommended for Development)

#### 1. Configure Environment

Create a `.env` file:

```bash
cp env.example .env
```

Edit `.env` with your Grafana Cloud credentials:

```bash
# Your Grafana Cloud Instance ID (found in Grafana Cloud portal)
GRAFANA_CLOUD_INSTANCE_ID=1433112

# Your Grafana Cloud API Token (generate in Access Policies)
GRAFANA_CLOUD_API_TOKEN=glc_xxxxxxxxxxxxx

# Your region's OTLP endpoint
GRAFANA_CLOUD_OTLP_ENDPOINT=https://otlp-gateway-prod-gb-south-1.grafana.net/otlp
```

> **Note**: Never commit the `.env` file. It's already in `.gitignore`.

#### 2. Start the Collector

```bash
docker-compose up -d
# OR using make
make start
```

#### 3. Check Status

```bash
# Check if running
docker-compose ps

# View logs
docker-compose logs -f

# Check health
curl http://localhost:13133/
```

### Option B: Building Custom Image (Production)

If you want to build a custom image with your configuration baked in:

#### 1. Configure Environment

Same as Option A - create `.env` file.

#### 2. Build Custom Image

```bash
make build
# OR
docker build -t tyklink/otel-collector:latest .
```

#### 3. Start with Custom Image

```bash
make build-start
# OR
docker-compose -f docker-compose.build.yml up -d
```

#### 4. Push to Registry (Optional)

```bash
# Tag for your registry
docker tag tyklink/otel-collector:latest your-registry.com/tyklink/otel-collector:latest

# Push
docker push your-registry.com/tyklink/otel-collector:latest

# OR use make (interactive)
make push
```

## Ports

| Port  | Protocol | Description                    |
|-------|----------|--------------------------------|
| 4317  | gRPC     | OTLP gRPC receiver            |
| 4318  | HTTP     | OTLP HTTP receiver            |
| 8888  | HTTP     | Collector internal metrics    |
| 8889  | HTTP     | Prometheus exporter metrics   |
| 13133 | HTTP     | Health check endpoint         |

## Network

The collector creates a Docker network named `otel-network` that other services can join to send telemetry data.

### Connect Your Services

#### Option 1: Docker Compose (Recommended)

Add to your service's `docker-compose.yml`:

```yaml
services:
  your-service:
    # ... your service config
    environment:
      - OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4318
      - USE_LOCAL_COLLECTOR=true
    networks:
      - otel-network

networks:
  otel-network:
    external: true
    name: otel-network
```

#### Option 2: Host Network

For services running on the host (not in Docker):

```bash
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318
export USE_LOCAL_COLLECTOR=true
```

## Configuration

The collector configuration is in `otel-collector-config.yaml`.

### Key Components

#### Receivers
- **OTLP gRPC**: Port 4317
- **OTLP HTTP**: Port 4318

#### Processors
- **batch**: Batches telemetry data for efficiency
- **resourcedetection**: Adds environment and system metadata
- **transform**: Cleans up unnecessary attributes

#### Exporters
- **otlphttp/grafana_cloud**: Sends traces and metrics to Grafana Cloud
- **otlphttp/grafana_cloud_logs**: Sends logs to Loki (Grafana Cloud)
- **debug**: Logs to console for debugging

#### Pipelines
- **traces**: OTLP → processors → Grafana Cloud
- **metrics**: OTLP → processors → Grafana Cloud
- **logs**: OTLP → processors → Loki

## Services Using This Collector

1. **linktrax-main** - Main application (Nuxt 3)
2. **redirect-trace-service** - Redirect tracing (NestJS)
3. **web-scraper-service** - Web scraping (NestJS)

## Monitoring

### View Collector Metrics

```bash
curl http://localhost:8888/metrics
```

### View Exported Metrics

```bash
curl http://localhost:8889/metrics
```

### Check Health

```bash
curl http://localhost:13133/
```

## Troubleshooting

### Collector Not Starting

Check logs:
```bash
docker-compose logs
```

Common issues:
- Missing `.env` file
- Invalid Grafana Cloud credentials
- Port conflicts (4317, 4318, 8888, 8889, 13133)

### Data Not Appearing in Grafana

1. Check collector logs:
   ```bash
   docker-compose logs -f
   ```

2. Look for export errors in debug output

3. Verify Grafana Cloud credentials in `.env`

4. Test endpoint:
   ```bash
   curl -X POST http://localhost:4318/v1/traces \
     -H "Content-Type: application/json" \
     -d '{"resourceSpans":[]}'
   ```

### Services Can't Connect

Check network:
```bash
docker network inspect otel-network
```

Verify services are on the same network:
```bash
docker inspect <container_name> | grep NetworkMode
```

### Debug Mode

Enable verbose debug logging by editing `otel-collector-config.yaml`:

```yaml
exporters:
  debug:
    verbosity: detailed  # Change to 'normal' or 'detailed'
    sampling_initial: 1  # Log first N spans
    sampling_thereafter: 1  # Then log every Nth span
```

Restart collector:
```bash
docker-compose restart
```

## Updating Configuration

After modifying `otel-collector-config.yaml`:

```bash
docker-compose restart
```

## Stopping the Collector

```bash
# Stop but keep data
docker-compose stop

# Stop and remove container
docker-compose down

# Stop and remove everything (network too)
docker-compose down --remove-orphans
```

## Production Considerations

### Security

1. **Never commit `.env`** - Contains sensitive credentials
2. **Use secrets management** in production (HashiCorp Vault, AWS Secrets Manager, etc.)
3. **Enable TLS** for OTLP receivers if exposed to internet
4. **Firewall rules** - Restrict access to collector ports

### Performance

1. **Batch processor** - Already configured for efficiency
2. **Memory limits** - Add to docker-compose.yml:
   ```yaml
   services:
     otel-collector:
       deploy:
         resources:
           limits:
             memory: 512M
   ```
3. **Sampling** - Consider tail-based sampling for high-volume services

### Reliability

1. **Health checks** - Already configured
2. **Restart policy**:
   ```yaml
   services:
     otel-collector:
       restart: unless-stopped
   ```
3. **Monitoring** - Monitor the collector itself in Grafana

## Architecture

```
┌─────────────────────┐
│  linktrax-main      │──┐
│  (Nuxt 3)           │  │
└─────────────────────┘  │
                         │
┌─────────────────────┐  │    ┌─────────────────────┐    ┌──────────────────┐
│  redirect-trace     │──┼───>│  OTEL Collector     │───>│  Grafana Cloud   │
│  (NestJS)           │  │    │  (Docker)           │    │                  │
└─────────────────────┘  │    │                     │    │  - Tempo (traces)│
                         │    │  Ports:             │    │  - Mimir (metrics│
┌─────────────────────┐  │    │  - 4317 (gRPC)     │    │  - Loki (logs)   │
│  web-scraper        │──┘    │  - 4318 (HTTP)     │    └──────────────────┘
│  (NestJS)           │       └─────────────────────┘
└─────────────────────┘
```

## Security

⚠️ **Important**: Never commit credentials to version control!

- Credentials are stored in `.env` file (gitignored)
- Config uses environment variable substitution
- See [SECURITY.md](./SECURITY.md) for full security guidelines

## Related Documentation

- [Security Guidelines](./SECURITY.md) - **Read this first!**
- [OpenTelemetry Collector Docs](https://opentelemetry.io/docs/collector/)
- [Grafana Cloud OTLP](https://grafana.com/docs/grafana-cloud/send-data/otlp/)
- linktrax-main: `docs/OBSERVABILITY.md`, `docs/LOGGING.md`

## Environment Variables Reference

| Variable | Description | Example |
|----------|-------------|---------|
| `GRAFANA_CLOUD_INSTANCE_ID` | Your Grafana Cloud instance ID | `1433112` |
| `GRAFANA_CLOUD_API_TOKEN` | Your Grafana Cloud API token | `glc_xxxxxxxxxxxxx` |
| `GRAFANA_CLOUD_OTLP_ENDPOINT` | OTLP endpoint for your region | `https://otlp-gateway-prod-gb-south-1.grafana.net/otlp` |

### How to Get These Values

1. **Instance ID**: Found in your Grafana Cloud portal URL or instance settings
2. **API Token**: 
   - Go to Grafana Cloud → Access Policies
   - Create a new token with `metrics:write`, `logs:write`, and `traces:write` permissions
   - Token format: `glc_xxxxxxxxxxxxx`
3. **OTLP Endpoint**: Based on your region (gb-south-1, us-central1, etc.)

## Support

For issues or questions:
1. Check collector logs: `docker-compose logs`
2. Review Grafana Cloud status page
3. Test with debug exporter enabled


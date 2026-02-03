# OpenTelemetry Collector - Custom Build
# Based on official otel/opentelemetry-collector-contrib image

FROM otel/opentelemetry-collector-contrib:latest

LABEL maintainer="Tyklink"
LABEL description="OpenTelemetry Collector with ClickHouse exporter"
LABEL version="1.0.0"

COPY --chmod=644 otel-collector-config.yaml /etc/otel-collector-config.yaml

# OTLP receivers + health check
EXPOSE 4317 4318 13133

# Use custom config by default
CMD ["--config=/etc/otel-collector-config.yaml"]

# OpenTelemetry Collector - Custom Build
# Based on official otel/opentelemetry-collector-contrib image
# Note: This is a distroless image with no shell

FROM otel/opentelemetry-collector-contrib:latest

# Metadata
LABEL maintainer="Tyklink"
LABEL description="Custom OpenTelemetry Collector for Tyklink services"
LABEL version="1.0.0"

# Copy configuration file
# Note: Base image already runs as non-root user, no chmod needed
COPY --chmod=644 otel-collector-config.yaml /etc/otel-collector-config.yaml

# Expose ports
# 4317: OTLP gRPC receiver
# 4318: OTLP HTTP receiver
# 8888: Prometheus metrics (collector internal)
# 8889: Prometheus exporter metrics
# 13133: Health check extension
EXPOSE 4317 4318 8888 8889 13133

# The base image already has ENTRYPOINT and CMD configured
# We don't need to override them since we're using the default config path


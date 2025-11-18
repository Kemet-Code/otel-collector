# Security Guidelines for OTEL Collector

## ⚠️ Important Security Notes

### 1. Never Commit Credentials

The following files contain or should contain sensitive credentials:

- ❌ **NEVER commit** `.env` files
- ❌ **NEVER commit** credentials in `otel-collector-config.yaml`
- ✅ **Always use** environment variables via `.env` file

### 2. Configuration Security

The `otel-collector-config.yaml` uses environment variable substitution:

```yaml
extensions:
  basicauth/grafana_cloud:
    client_auth:
      username: ${env:GRAFANA_CLOUD_INSTANCE_ID}
      password: ${env:GRAFANA_CLOUD_API_TOKEN}
```

This means credentials come from the `.env` file, not hardcoded in the config.

### 3. Protected Files

Already in `.gitignore`:
```
.env
volumes/
*.log
```

### 4. Credential Management

#### Development
Store credentials in `.env` file (not committed):
```bash
GRAFANA_CLOUD_INSTANCE_ID=1433112
GRAFANA_CLOUD_API_TOKEN=glc_xxxxxxxxxxxxx
```

#### Production
Use a secrets management system:
- **Docker Swarm**: Docker secrets
- **Kubernetes**: Kubernetes secrets
- **AWS**: AWS Secrets Manager or Parameter Store
- **GCP**: Secret Manager
- **Azure**: Key Vault
- **General**: HashiCorp Vault

Example with Docker secrets:
```yaml
version: '3.8'
services:
  otel-collector:
    secrets:
      - grafana_token
    environment:
      - GRAFANA_CLOUD_API_TOKEN_FILE=/run/secrets/grafana_token

secrets:
  grafana_token:
    external: true
```

### 5. Token Permissions

When creating Grafana Cloud tokens, use **minimum required permissions**:

Required:
- ✅ `metrics:write`
- ✅ `logs:write`
- ✅ `traces:write`

Not needed:
- ❌ `admin` permissions
- ❌ `user:read` permissions
- ❌ `dashboards:write` permissions

### 6. Network Security

#### Local Development
- Collector accessible only on `localhost`
- Services connect via Docker network

#### Production Considerations
1. **TLS/HTTPS**: Enable TLS for OTLP receivers if exposed
2. **Firewall**: Restrict collector ports to known services
3. **Authentication**: Consider adding auth for OTLP receivers
4. **Network isolation**: Use private networks/VPCs

### 7. Rotating Credentials

Periodically rotate your Grafana Cloud tokens:

1. Create new token in Grafana Cloud
2. Update `.env` file with new token
3. Restart collector: `docker-compose restart`
4. Revoke old token in Grafana Cloud

### 8. Monitoring Access

Monitor who accesses the collector:
- Check collector logs for unauthorized access attempts
- Monitor Grafana Cloud for unexpected data sources
- Review access policies regularly

### 9. Incident Response

If credentials are compromised:

1. **Immediately revoke** the token in Grafana Cloud
2. **Generate new token** with fresh credentials
3. **Update** all services using the collector
4. **Review logs** for suspicious activity
5. **Audit** who had access to the credentials

### 10. Checklist Before Deployment

- [ ] `.env` file is in `.gitignore`
- [ ] No credentials in version control
- [ ] Token has minimal required permissions
- [ ] Firewall rules restrict access
- [ ] TLS enabled for production
- [ ] Credentials stored in secrets manager (production)
- [ ] Monitoring/alerting configured
- [ ] Incident response plan documented

## Audit Log

Keep a log of credential changes:

```markdown
| Date       | Action           | User  | Token ID | Reason          |
|------------|------------------|-------|----------|-----------------|
| 2025-11-18 | Token created    | Admin | xxx123   | Initial setup   |
| 2025-12-18 | Token rotated    | Admin | xxx456   | Monthly rotation|
```

## Resources

- [Grafana Cloud Security](https://grafana.com/docs/grafana-cloud/account-management/authentication-and-permissions/)
- [OTEL Security Best Practices](https://opentelemetry.io/docs/specs/otel/configuration/security/)
- [Docker Secrets](https://docs.docker.com/engine/swarm/secrets/)


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
exporters:
  clickhouse:
    endpoint: ${env:CLICKHOUSE_DSN}
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
CLICKHOUSE_DSN=http://default:password@localhost:18123/otel
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
services:
  otel-collector:
    secrets:
      - clickhouse_password
    environment:
      - CLICKHOUSE_PASSWORD_FILE=/run/secrets/clickhouse_password

secrets:
  clickhouse_password:
    external: true
```

### 5. ClickHouse Permissions

When creating ClickHouse users, use **minimum required permissions**:

Required:
- ✅ `INSERT` on otel database
- ✅ `CREATE TABLE` (for auto schema)
- ✅ `CREATE DATABASE` (for auto schema)

Not needed:
- ❌ `admin` permissions
- ❌ Access to other databases

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

Periodically rotate your ClickHouse credentials:

1. Create new user/password in ClickHouse
2. Update `.env` file with new credentials
3. Restart collector: `docker-compose restart`
4. Remove old user in ClickHouse

### 8. Monitoring Access

Monitor who accesses the collector:
- Check collector logs for unauthorized access attempts
- Monitor ClickHouse for unexpected queries
- Review access policies regularly

### 9. Incident Response

If credentials are compromised:

1. **Immediately change** the ClickHouse password
2. **Update** all services using the collector
3. **Review logs** for suspicious activity
4. **Audit** who had access to the credentials

### 10. Checklist Before Deployment

- [ ] `.env` file is in `.gitignore`
- [ ] No credentials in version control
- [ ] ClickHouse user has minimal required permissions
- [ ] Firewall rules restrict access
- [ ] TLS enabled for production
- [ ] Credentials stored in secrets manager (production)
- [ ] Monitoring/alerting configured
- [ ] Incident response plan documented

## Resources

- [ClickHouse Security](https://clickhouse.com/docs/en/guides/sre/user-management/configuring-security)
- [OTEL Security Best Practices](https://opentelemetry.io/docs/specs/otel/configuration/security/)
- [Docker Secrets](https://docs.docker.com/engine/swarm/secrets/)

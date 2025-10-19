# Docker Monitoring with Prometheus & Grafana

Complete monitoring stack for Docker containers with pre-configured dashboards and alerts.

## Stack Components

- **Prometheus** - Metrics collection and storage
- **Grafana** - Visualization and dashboards
- **Node Exporter** - Host system metrics
- **cAdvisor** - Container resource metrics
- **Alertmanager** - Alert routing and notifications

## Quick Start

```bash
# Start the monitoring stack
docker-compose up -d

# Check all containers are running
docker-compose ps

# Access the UIs
# Grafana:      http://localhost:3000 (admin/admin)
# Prometheus:   http://localhost:9090
# Alertmanager: http://localhost:9093
# cAdvisor:     http://localhost:8080
```

## First Time Setup

### 1. Login to Grafana

```
URL: http://localhost:3000
Username: admin
Password: admin
(Change password on first login)
```

### 2. Import Pre-Built Dashboards

Grafana → Dashboards → Import

**Recommended Docker Dashboards:**

| Dashboard | ID | Description |
|-----------|----|-----------| 
| Docker Container & Host Metrics | 19792 | Comprehensive view |
| Docker Monitoring | 893 | Container metrics |
| cAdvisor exporter | 14282 | Detailed container stats |
| Node Exporter Full | 1860 | Host system metrics |

```bash
# Import by ID
1. Go to http://localhost:3000/dashboard/import
2. Enter dashboard ID (e.g., 19792)
3. Click "Load"
4. Select "Prometheus" as data source
5. Click "Import"
```

### 3. Configure Slack Alerts (Optional)

Edit `alertmanager/config.yml`:

```yaml
global:
  slack_api_url: 'https://hooks.slack.com/services/YOUR/WEBHOOK/URL'

receivers:
  - name: 'slack-notifications'
    slack_configs:
      - channel: '#docker-alerts'
```

Restart Alertmanager:
```bash
docker-compose restart alertmanager
```

## What's Being Monitored

### Container Metrics (cAdvisor)

✅ CPU usage per container
✅ Memory usage and limits
✅ Network I/O
✅ Disk I/O
✅ Container restarts
✅ Container states

### Host Metrics (Node Exporter)

✅ CPU usage (total, per core)
✅ Memory usage
✅ Disk usage and I/O
✅ Network traffic
✅ System load
✅ Filesystem stats

### Application Metrics

✅ HTTP request rate
✅ Response times
✅ Error rates
✅ Custom business metrics

## Adding Your Application

### 1. Add Prometheus Metrics to Your App

#### Node.js (Express)

```javascript
const promClient = require('prom-client');
const express = require('express');

const app = express();

// Enable default metrics
const register = new promClient.Registry();
promClient.collectDefaultMetrics({ register });

// Expose metrics endpoint
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});
```

#### Python (Flask)

```python
from prometheus_flask_exporter import PrometheusMetrics
from flask import Flask

app = Flask(__name__)
metrics = PrometheusMetrics(app)

# Metrics automatically exposed at /metrics
```

#### Java (Spring Boot)

```xml
<!-- pom.xml -->
<dependency>
    <groupId>io.micrometer</groupId>
    <artifactId>micrometer-registry-prometheus</artifactId>
</dependency>
```

```properties
# application.properties
management.endpoints.web.exposure.include=prometheus
management.metrics.export.prometheus.enabled=true
```

### 2. Add to docker-compose.yml

```yaml
services:
  my-app:
    image: my-app:latest
    ports:
      - "8080:8080"
    networks:
      - monitoring  # ← Join monitoring network
    labels:
      - "prometheus.scrape=true"
      - "prometheus.port=8080"
      - "prometheus.path=/metrics"
```

### 3. Add to prometheus.yml

```yaml
scrape_configs:
  - job_name: 'my-app'
    static_configs:
      - targets: ['my-app:8080']
        labels:
          service: 'my-app'
          environment: 'production'
```

### 4. Reload Prometheus

```bash
# Send reload signal
curl -X POST http://localhost:9090/-/reload

# Or restart
docker-compose restart prometheus
```

## Pre-Configured Alerts

### Critical Alerts

🚨 **ContainerDown** - Service is unreachable
🚨 **HighErrorRate** - HTTP 5xx errors > 5%

### Warning Alerts

⚠️ **HighCPUUsage** - CPU > 80% for 5 minutes
⚠️ **HighMemoryUsage** - Memory > 90%
⚠️ **ContainerRestarting** - Multiple restarts detected
⚠️ **DiskSpaceLow** - Disk < 10% free

## Common Queries

### CPU Usage by Container

```promql
rate(container_cpu_usage_seconds_total{name!=""}[5m]) * 100
```

### Memory Usage by Container

```promql
container_memory_usage_bytes{name!=""} / 1024 / 1024
```

### Network Traffic

```promql
# Inbound
rate(container_network_receive_bytes_total[5m])

# Outbound
rate(container_network_transmit_bytes_total[5m])
```

### Container Restarts

```promql
rate(container_last_seen[5m])
```

### Top 5 CPU Consumers

```promql
topk(5, rate(container_cpu_usage_seconds_total[5m]))
```

### HTTP Request Rate

```promql
rate(http_requests_total[5m])
```

### HTTP Error Rate

```promql
rate(http_requests_total{status=~"5.."}[5m])
```

## Grafana Dashboard Tips

### Custom Dashboard Variables

```
Name: container
Type: Query
Query: label_values(container_cpu_usage_seconds_total, name)
```

### Useful Visualizations

1. **Time Series** - CPU/Memory over time
2. **Gauge** - Current CPU/Memory percentage
3. **Stat** - Single value (uptime, request count)
4. **Table** - List of containers with stats
5. **Bar Chart** - Compare containers

### Alert Rules in Grafana

```
1. Create panel with query
2. Alert tab → Create Alert
3. Set conditions (e.g., value > 80)
4. Configure notification channel
5. Save dashboard
```

## Production Best Practices

### 1. Retention Policy

```yaml
# prometheus.yml
global:
  scrape_interval: 15s  # How often to scrape
  
# Startup flags
--storage.tsdb.retention.time=15d  # Keep 15 days
--storage.tsdb.retention.size=50GB  # Or max 50GB
```

### 2. Resource Limits

```yaml
# docker-compose.yml
services:
  prometheus:
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 2G
```

### 3. Persistent Storage

```yaml
volumes:
  prometheus_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /data/prometheus  # SSD recommended
```

### 4. High Availability

```yaml
# Run multiple Prometheus instances
services:
  prometheus-1:
    # ...
  prometheus-2:
    # ...
  
  # Use Thanos for long-term storage
  thanos:
    image: thanosio/thanos
```

### 5. Security

```yaml
# Enable authentication
# Add to prometheus.yml
basic_auth:
  username: admin
  password_file: /etc/prometheus/.htpasswd
```

## Troubleshooting

### Prometheus Not Scraping?

```bash
# Check targets status
curl http://localhost:9090/api/v1/targets

# Check Prometheus logs
docker logs prometheus

# Verify network connectivity
docker exec prometheus wget -O- http://my-app:8080/metrics
```

### Grafana Can't Connect to Prometheus?

```bash
# Test from Grafana container
docker exec grafana curl http://prometheus:9090/api/v1/query?query=up

# Check they're on same network
docker network inspect monitoring
```

### High Memory Usage?

```bash
# Check Prometheus storage size
du -sh prometheus_data/

# Reduce retention time
--storage.tsdb.retention.time=7d

# Or add size limit
--storage.tsdb.retention.size=10GB
```

### Missing Metrics?

```bash
# Check scrape interval
# Verify metrics endpoint
curl http://localhost:8080/metrics

# Check Prometheus config
docker exec prometheus cat /etc/prometheus/prometheus.yml
```

## Backup and Restore

### Backup Prometheus Data

```bash
# Stop Prometheus
docker-compose stop prometheus

# Backup data
tar -czf prometheus-backup-$(date +%Y%m%d).tar.gz prometheus_data/

# Start Prometheus
docker-compose start prometheus
```

### Backup Grafana Dashboards

```bash
# Export all dashboards
curl -H "Authorization: Bearer YOUR_API_KEY" \
  http://localhost:3000/api/search?type=dash-db | \
  jq -r '.[] | .uid' | \
  xargs -I {} curl -H "Authorization: Bearer YOUR_API_KEY" \
  http://localhost:3000/api/dashboards/uid/{} > dashboard-{}.json
```

## Scaling Considerations

### Metrics Volume

```
Estimate: containers × metrics × scrape_interval

Example:
- 50 containers
- 100 metrics each
- 15s scrape interval
- 15 days retention

= ~15GB storage
```

### When to Scale

- \> 100 containers → Consider Thanos
- \> 1000 metrics/sec → Add Prometheus replicas
- Long-term storage → Use Thanos or Cortex
- Global view → Prometheus Federation

## Complete Stack URLs

```
Grafana:         http://localhost:3000
Prometheus:      http://localhost:9090
Alertmanager:    http://localhost:9093
Node Exporter:   http://localhost:9100/metrics
cAdvisor:        http://localhost:8080
Demo App:        http://localhost:8081
```

## Key Takeaways

✅ Complete monitoring in minutes
✅ Pre-configured alerts for common issues
✅ Beautiful dashboards out of the box
✅ Scales from dev to production
✅ Industry-standard tools
✅ Open source and free

**Reference:** Docker Field Manual, Chapter 8, Pages 245-270

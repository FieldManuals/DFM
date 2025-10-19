# Production Java/Spring Boot Dockerfile Template

**Optimized multi-stage Docker build for Java applications**

## Features

✅ **Layered JAR** - Spring Boot layers for optimal caching
✅ **Multi-stage build** - Maven build separate from runtime
✅ **JRE only** - No JDK in production (smaller image)
✅ **Non-root user** - Security best practice
✅ **JVM optimization** - Container-aware settings
✅ **Health checks** - Spring Boot Actuator integration
✅ **Dependency caching** - Fast rebuilds

## Quick Start

### Build and Run

```bash
# Build
docker build -t java-app:1.0 .

# Run
docker run -d --name app -p 8080:8080 java-app:1.0

# Test
curl http://localhost:8080
curl http://localhost:8080/actuator/health

# Check size
docker images java-app:1.0
# ~250-300MB (vs 500MB+ without optimization)
```

### With Environment Variables

```bash
docker run -d --name app \
  -p 8080:8080 \
  -e ENVIRONMENT=production \
  -e SPRING_PROFILES_ACTIVE=prod \
  -e JAVA_OPTS="-Xmx512m" \
  java-app:1.0
```

## Dockerfile Breakdown

### Stage 1: Maven Build

```dockerfile
FROM maven:3.9-eclipse-temurin-17 AS builder
```
- Official Maven image with Java 17
- Eclipse Temurin (formerly AdoptOpenJDK)

```dockerfile
COPY pom.xml .
RUN mvn dependency:go-offline -B
```
- Download dependencies first
- Cached layer - only rebuilds if pom.xml changes
- `-B` = batch mode (no progress bars)

```dockerfile
RUN mvn clean package -DskipTests -B
```
- Build JAR file
- Skip tests in Docker (run in CI/CD instead)

```dockerfile
RUN java -Djarmode=layertools -jar target/*.jar extract
```
- **Key optimization!** Extract JAR into layers
- Dependencies separate from application code
- Better Docker layer caching

### Layers Extracted

Spring Boot creates these layers:
1. **dependencies** - Third-party libraries (rarely change)
2. **spring-boot-loader** - Spring Boot framework (rarely change)
3. **snapshot-dependencies** - SNAPSHOT versions
4. **application** - Your code (changes frequently)

### Stage 2: Production Runtime

```dockerfile
FROM eclipse-temurin:17-jre-alpine
```
- JRE only (no compiler = smaller)
- Alpine variant for minimal size
- Temurin = reliable, production-grade JVM

```dockerfile
COPY --from=builder /build/target/extracted/dependencies/ ./
COPY --from=builder /build/target/extracted/spring-boot-loader/ ./
COPY --from=builder /build/target/extracted/snapshot-dependencies/ ./
COPY --from=builder /build/target/extracted/application/ ./
```
- Copy layers in order of change frequency
- Docker caches unchanged layers
- Application code change = only last layer rebuilds

```dockerfile
ENV JAVA_OPTS="-XX:+UseContainerSupport \
    -XX:MaxRAMPercentage=75.0 \
    -XX:+UseG1GC \
    -XX:+UseStringDeduplication \
    -Djava.security.egd=file:/dev/./urandom"
```
- **Container-aware JVM settings**
- Respects Docker memory limits
- G1GC for better GC performance
- Faster startup with urandom

## JVM Optimization Explained

### Container Support

```bash
-XX:+UseContainerSupport
```
- JVM reads Docker container limits
- Auto-adjusts heap size
- Without this: JVM might use host RAM (OOM kills)

### Memory Percentage

```bash
-XX:MaxRAMPercentage=75.0
```
- Use 75% of container memory for heap
- Leaves 25% for off-heap, metaspace, etc.
- Example: 512MB container = 384MB heap

### G1 Garbage Collector

```bash
-XX:+UseG1GC
```
- Modern, low-latency GC
- Better than default parallel GC for containers
- Handles large heaps efficiently

### Faster Startup

```bash
-Djava.security.egd=file:/dev/./urandom
```
- Use faster random number generation
- Reduces startup time
- Safe for most applications

## Image Size Optimization

### Without Optimization
```dockerfile
FROM openjdk:17
COPY target/*.jar app.jar
# Result: 500-600MB
```

### With JRE + Layering
```dockerfile
FROM eclipse-temurin:17-jre-alpine
# Layered JAR extraction
# Result: 250-300MB (50% smaller!)
```

### Size Breakdown
```
Base JRE:                80MB
Dependencies:           150MB
Spring Boot Loader:      10MB
Application Code:        10MB
Total:                 ~250MB
```

## Build Time Optimization

### First Build (Cold)
```bash
time docker build -t java-app .
# real: 2m 30s (Maven downloads everything)
```

### Code Change Only
```bash
# Change Java file, rebuild
time docker build -t java-app .
# real: 45s (dependencies cached!)
```

### Dependency Change
```bash
# Add dependency to pom.xml
time docker build -t java-app .
# real: 1m 30s (re-download new dependencies)
```

## Spring Boot Actuator

### Health Endpoints

```bash
# Simple health check
curl http://localhost:8080/actuator/health

# Detailed health
curl http://localhost:8080/actuator/health | jq

# Application info
curl http://localhost:8080/actuator/info

# Metrics
curl http://localhost:8080/actuator/metrics
```

### Configure in application.properties

```properties
# Expose endpoints
management.endpoints.web.exposure.include=health,info,metrics,prometheus

# Show health details
management.endpoint.health.show-details=always

# Custom info
info.app.name=My Java App
info.app.version=1.0.0
```

## Development vs Production

### Development (docker-compose.yml)

```yaml
version: '3.8'
services:
  app:
    build:
      context: .
      target: builder  # Stop at build stage
    volumes:
      - .:/build  # Mount source for hot reload
      - ~/.m2:/root/.m2  # Cache Maven dependencies
    environment:
      - SPRING_PROFILES_ACTIVE=dev
      - SPRING_DEVTOOLS_RESTART_ENABLED=true
    ports:
      - "8080:8080"
      - "5005:5005"  # Debug port
    command: mvn spring-boot:run -Dspring-boot.run.jvmArguments="-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005"
```

### Production

```yaml
version: '3.8'
services:
  app:
    image: registry.example.com/java-app:1.0.0
    environment:
      - SPRING_PROFILES_ACTIVE=prod
      - JAVA_OPTS=-Xmx512m -Xms512m
    deploy:
      replicas: 3
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/actuator/health"]
      interval: 30s
      timeout: 3s
      retries: 3
    restart: unless-stopped
```

## Database Integration

### PostgreSQL

```xml
<!-- pom.xml -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-jpa</artifactId>
</dependency>
<dependency>
    <groupId>org.postgresql</groupId>
    <artifactId>postgresql</artifactId>
</dependency>
```

```properties
# application.properties
spring.datasource.url=jdbc:postgresql://db:5432/myapp
spring.datasource.username=postgres
spring.datasource.password=${DB_PASSWORD}
spring.jpa.hibernate.ddl-auto=validate
```

```yaml
# docker-compose.yml
services:
  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_PASSWORD: secret
    volumes:
      - postgres_data:/var/lib/postgresql/data
  
  app:
    build: .
    environment:
      DB_PASSWORD: secret
    depends_on:
      - db
```

## Memory Configuration

### Container Limits

```bash
# Run with 512MB memory limit
docker run -d --name app \
  -m 512m \
  -e JAVA_OPTS="-Xmx384m -Xms384m" \
  java-app:1.0
```

### Calculation Rule

```
Container Memory = Heap + Metaspace + Thread Stack + Off-Heap + OS

Example for 512MB container:
- Heap (Xmx):        384MB (75%)
- Metaspace:          64MB
- Thread Stacks:      32MB
- Off-Heap:           16MB
- OS Buffer:          16MB
Total:               512MB
```

### Common Configurations

| Container | Heap (Xmx) | Recommendation |
|-----------|------------|----------------|
| 256MB | 192MB | Minimal, for sidecars |
| 512MB | 384MB | Small services |
| 1GB | 768MB | Medium services |
| 2GB | 1536MB | Large services |
| 4GB | 3GB | Heavy processing |

## Monitoring with Prometheus

### Add Dependency

```xml
<dependency>
    <groupId>io.micrometer</groupId>
    <artifactId>micrometer-registry-prometheus</artifactId>
</dependency>
```

### Enable Endpoint

```properties
management.endpoints.web.exposure.include=health,info,prometheus
management.metrics.export.prometheus.enabled=true
```

### Scrape Config

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'spring-boot-app'
    metrics_path: '/actuator/prometheus'
    static_configs:
      - targets: ['app:8080']
```

## Troubleshooting

### Out of Memory Errors?

```bash
# Check JVM settings
docker logs app | grep -i "heap\|memory"

# Increase heap size
docker run -e JAVA_OPTS="-Xmx1g" java-app

# Or increase container limit
docker run -m 1g java-app
```

### Slow Startup?

```bash
# Check startup time
docker logs app | grep "Started Application"

# Add startup logging
-Dlogging.level.org.springframework=DEBUG

# Use faster random
-Djava.security.egd=file:/dev/./urandom  # Already in template!
```

### Permission Denied?

```bash
# Check file ownership
docker run -it --rm java-app ls -la /app

# Should show: appuser appuser
```

### Can't Connect to Database?

```bash
# Test network connectivity
docker exec app curl db:5432

# Check environment variables
docker exec app env | grep DATABASE
```

## GraalVM Native Image (Advanced)

For ~50MB images with instant startup:

```dockerfile
FROM ghcr.io/graalvm/graalvm-ce:ol9-java17 AS builder

WORKDIR /build
COPY . .

RUN ./mvnw native:compile -Pnative -DskipTests

FROM alpine:3.19
COPY --from=builder /build/target/app /app
ENTRYPOINT ["/app"]

# Result: 
# Size: ~50MB (vs 250MB)
# Startup: <100ms (vs 5-10s)
```

## Complete Example

See `example-app/` directory for:
- Full Spring Boot REST API
- PostgreSQL integration
- Redis caching
- Actuator monitoring
- Docker Compose setup
- Kubernetes manifests
- CI/CD pipeline

## Key Takeaways

✅ Layered JARs dramatically improve Docker caching
✅ JRE-only images are 50% smaller than JDK
✅ Container-aware JVM prevents OOM kills
✅ Spring Boot Actuator provides production-ready monitoring
✅ Multi-stage builds separate concerns cleanly
✅ Eclipse Temurin provides reliable, production-grade JVM

**Reference:** Docker Field Manual, Chapter 4, Pages 92-98

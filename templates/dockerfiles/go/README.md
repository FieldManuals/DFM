# Production Go Dockerfile Template

**Minimal, secure, and blazing fast Go containers**

## Features

✅ **Scratch-based** - Absolute minimal image (5-15MB!)
✅ **Static binary** - Zero dependencies
✅ **Multi-stage build** - Separate build from runtime
✅ **Security** - Non-root user, minimal attack surface
✅ **Three variants** - Scratch, Alpine, Distroless
✅ **Fast builds** - Go mod caching
✅ **Production-ready** - Optimized and hardened

## Quick Start

### Build and Run (Scratch)

```bash
# Build
docker build -t go-app:1.0 .

# Run
docker run -d --name app -p 8080:8080 go-app:1.0

# Test
curl http://localhost:8080
curl http://localhost:8080/health

# Check size
docker images go-app:1.0
# REPOSITORY   TAG   SIZE
# go-app       1.0   ~8MB  🚀
```

### Build Alpine Variant

```bash
docker build -f Dockerfile.alpine -t go-app:alpine .

# Size: ~15MB (includes shell, curl for health checks)
```

### Build Distroless Variant

```bash
docker build -f Dockerfile.distroless -t go-app:distroless .

# Size: ~10MB (minimal runtime, no shell)
```

## Image Size Comparison

```
go-app:scratch      8MB   ⭐ Smallest, no shell
go-app:distroless   10MB  ⭐ Google's minimal images
go-app:alpine       15MB  ⭐ Includes shell & curl
go-app:debian       25MB  ⭐ Full shell utilities

For comparison:
python:3.11-slim    150MB
node:18-alpine      120MB
openjdk:17-slim     200MB

Go wins! 🎉
```

## Dockerfile Breakdown

### Stage 1: Builder

```dockerfile
FROM golang:1.21-alpine AS builder
```
- Official Go image with build tools
- Alpine variant for smaller builder

```dockerfile
COPY go.mod go.sum ./
RUN go mod download
```
- Copy dependency files first
- Cached layer - only rebuilds if dependencies change

```dockerfile
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags='-w -s -extldflags "-static"' \
    -a \
    -o app
```
- `CGO_ENABLED=0`: Static linking (no C dependencies)
- `-ldflags='-w -s'`: Strip debug info (smaller binary)
- `-extldflags "-static"`: Fully static binary
- `-a`: Rebuild all packages

### Stage 2: Runtime (Scratch)

```dockerfile
FROM scratch
```
- Empty base image (0MB)
- Only contains what you copy

```dockerfile
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
```
- Required for HTTPS requests
- Copied from builder

```dockerfile
USER 65534:65534
```
- Nobody user (non-root)
- Numeric UID (required for scratch)

```dockerfile
ENTRYPOINT ["/app"]
```
- Exec form (no shell needed)
- Binary runs as PID 1

## Variant Comparison

### When to Use Scratch

**Best for:**
- Minimal image size is critical
- No debugging needed in production
- API servers, microservices
- Static binary with no external calls

**Limitations:**
- No shell (can't `docker exec sh`)
- No debugging tools
- No health check command (need HTTP probe)

```dockerfile
FROM scratch
COPY --from=builder /build/app /app
USER 65534:65534
ENTRYPOINT ["/app"]

# Result: 5-15MB
```

### When to Use Alpine

**Best for:**
- Need shell for debugging
- Want health check with curl
- Occasional container inspection
- Good balance of size and utility

**Advantages:**
- Shell access
- Package manager (apk)
- Debugging tools
- Still small (~15MB)

```dockerfile
FROM alpine:3.19
RUN apk add --no-cache ca-certificates curl
USER appuser
ENTRYPOINT ["./app"]

# Result: 15-25MB
```

### When to Use Distroless

**Best for:**
- Security-conscious deployments
- Production with no debugging
- Google Cloud Platform users
- Compliance requirements

**Advantages:**
- More secure than Alpine
- No shell (attack prevention)
- Google-maintained
- Includes runtime libraries

```dockerfile
FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=builder /build/app /app
ENTRYPOINT ["/app"]

# Result: 10-20MB
```

## Project Structure

```
go-app/
├── cmd/
│   └── server/
│       └── main.go           # Application entry point
├── internal/                 # Private application code
│   ├── handlers/
│   ├── models/
│   └── services/
├── pkg/                      # Public libraries
├── go.mod                    # Dependencies
├── go.sum                    # Dependency checksums
├── Dockerfile                # Scratch variant
├── Dockerfile.alpine         # Alpine variant
├── Dockerfile.distroless     # Distroless variant
└── README.md
```

## Build Optimization

### Layer Caching

```dockerfile
# ✅ Good - dependencies cached
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN go build

# ❌ Bad - cache invalidated on any code change
COPY . .
RUN go mod download
RUN go build
```

### Build Time Comparison

```bash
# First build
time docker build -t go-app .
# real: 45s

# Code change only (cached dependencies)
time docker build -t go-app .
# real: 5s  ⚡

# Dependency change
time docker build -t go-app .
# real: 25s
```

## Development vs Production

### Development (with Air for hot reload)

```dockerfile
FROM golang:1.21-alpine

# Install Air for hot reload
RUN go install github.com/cosmtrek/air@latest

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

CMD ["air", "-c", ".air.toml"]
```

```yaml
# docker-compose.yml
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile.dev
    volumes:
      - .:/app
    ports:
      - "8080:8080"
```

### Production

```dockerfile
# Use scratch variant
FROM scratch
# Static binary
# No development tools
```

## Common Patterns

### With Database (PostgreSQL)

```go
import (
    "database/sql"
    _ "github.com/lib/pq"
)

func main() {
    db, err := sql.Open("postgres", os.Getenv("DATABASE_URL"))
    // ...
}
```

```dockerfile
# Note: lib/pq requires CGO for some features
# Use pgx for pure Go:
# github.com/jackc/pgx/v5

RUN CGO_ENABLED=0 go build ...  # Still works!
```

### With Environment Config

```go
package main

import "github.com/kelseyhightower/envconfig"

type Config struct {
    Port        string `envconfig:"PORT" default:"8080"`
    Environment string `envconfig:"ENVIRONMENT" default:"development"`
    DatabaseURL string `envconfig:"DATABASE_URL" required:"true"`
}

func main() {
    var cfg Config
    envconfig.Process("", &cfg)
    // Use cfg...
}
```

### With Graceful Shutdown

```go
func main() {
    srv := &http.Server{Addr: ":8080", Handler: router}

    go func() {
        if err := srv.ListenAndServe(); err != nil {
            log.Println(err)
        }
    }()

    // Wait for interrupt
    c := make(chan os.Signal, 1)
    signal.Notify(c, os.Interrupt, syscall.SIGTERM)
    <-c

    // Graceful shutdown
    ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
    defer cancel()
    srv.Shutdown(ctx)
}
```

## Security Best Practices

### 1. Non-Root User ✅

```dockerfile
# Scratch (numeric UID)
USER 65534:65534

# Alpine (named user)
RUN adduser -D -u 1000 appuser
USER appuser
```

### 2. Static Binary

```dockerfile
CGO_ENABLED=0  # No C dependencies = more secure
```

### 3. Minimal Base

```dockerfile
FROM scratch  # Nothing to exploit!
```

### 4. No Secrets in Image

```bash
# Bad
ENV API_KEY=secret

# Good
docker run -e API_KEY=secret go-app
```

### 5. Read-Only Filesystem

```bash
docker run --read-only --tmpfs /tmp go-app
```

## Debugging

### Scratch Container (No Shell!)

```bash
# Can't do this:
docker exec -it container sh  # ❌ No shell

# Instead: Use ephemeral debug container
docker run -it --rm --pid=container:<id> --net=container:<id> alpine sh

# Or: Use Alpine variant for debugging
docker build -f Dockerfile.alpine -t go-app:debug .
```

### Check Binary Info

```bash
# File size
ls -lh app

# Check if static
ldd app  # Should say "not a dynamic executable"

# Check symbols (stripped?)
nm app | wc -l  # Small number = stripped
```

## Performance Benefits

### Startup Time

```
Scratch:    <1ms   ⚡⚡⚡
Alpine:     <5ms   ⚡⚡
Distroless: <2ms   ⚡⚡⚡
Python:     ~500ms
Node:       ~300ms
Java:       ~2000ms
```

### Memory Usage

```
Go (scratch):   5-10MB base
Python:         30-50MB base
Node.js:        20-40MB base
Java:           50-100MB base
```

### Cold Start (Serverless)

```
Go:     <100ms  ⭐
Python: ~500ms
Node:   ~300ms
Java:   ~2000ms
```

## Troubleshooting

### CGO Required?

Some packages require CGO (C bindings):

```bash
# Check if package needs CGO
go list -f '{{.CgoFiles}}' package/name

# If required, use Alpine instead of scratch
docker build -f Dockerfile.alpine -t go-app .
```

### HTTPS Fails?

```bash
# Missing CA certificates
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
```

### Timezone Issues?

```bash
# Copy timezone data
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo
ENV TZ=America/New_York
```

### Can't Debug?

```bash
# Use Alpine variant for debugging
docker build -f Dockerfile.alpine -t go-app:debug .

# Or use multi-stage target
docker build --target builder -t go-app:debug .
docker run -it go-app:debug sh
```

## Complete Example

See `example-app/` directory for:
- REST API with Gorilla Mux
- PostgreSQL integration
- Redis caching
- Graceful shutdown
- Docker Compose setup
- Kubernetes manifests
- CI/CD pipeline

## Key Takeaways

✅ Go produces the smallest container images (5-15MB)
✅ Static binaries = zero runtime dependencies
✅ Scratch base = maximum security (no OS vulnerabilities)
✅ Sub-second startup times
✅ Perfect for microservices and serverless
✅ Three variants: scratch (smallest), Alpine (debuggable), Distroless (secure)

**Go + Docker = Match made in heaven! 🚀**

**Reference:** Docker Field Manual, Chapter 4, Pages 92-98

# ============================================
# Build stage
# ============================================
FROM golang:1.21-alpine AS builder

# Install build dependencies
RUN apk add --no-cache git ca-certificates tzdata

WORKDIR /build

# Copy go mod files
COPY go.mod go.sum ./

# Download dependencies (cached layer)
RUN go mod download

# Copy source code
COPY . .

# Build binary
# CGO_ENABLED=0 for static linking
# -ldflags for smaller binary
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags='-w -s -extldflags "-static"' \
    -a \
    -o app \
    ./cmd/server

# ============================================
# Final stage - scratch (minimal)
# ============================================
FROM scratch

# Copy CA certificates for HTTPS
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Copy timezone data
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo

# Copy the binary
COPY --from=builder /build/app /app

# Expose port
EXPOSE 8080

# Health check (requires curl in scratch alternative)
# Use alpine or distroless if health checks needed

# Run as non-root (numeric UID for scratch)
USER 65534:65534

# Run the application
ENTRYPOINT ["/app"]

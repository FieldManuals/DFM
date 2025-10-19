# Chapter 6: Docker Security Examples

Production-ready security hardening examples demonstrating Docker security best practices.

## What's Inside

### 1. Read-Only Filesystem (`01-read-only-filesystem/`)
Run containers with immutable root filesystem, preventing runtime modifications.

**Key Features:**
- Root filesystem mounted read-only
- tmpfs mounts for temporary storage
- Prevents malware from modifying binaries
- Protection against container escape attacks

### 2. Minimal Attack Surface (`02-minimal-attack-surface/`)
Two approaches to minimize what attackers can exploit:

**Distroless Images:**
- No shell, no package manager, no utilities
- Only application and runtime dependencies
- 10-20MB smaller than Alpine
- Harder for attackers to run commands

**Hardened Alpine:**
- Minimal Alpine base with runtime only
- No build tools or convenience utilities
- Non-root user enforced
- Capability dropping

### 3. Secrets Management (`03-secrets-management/`)
Secure handling of sensitive data like passwords and API keys.

**Key Features:**
- Docker secrets (encrypted in Swarm)
- Never in environment variables
- Never in image layers
- Mounted as tmpfs (memory only)

## Quick Start

### Read-Only Filesystem
```bash
cd 01-read-only-filesystem
docker-compose up -d

# Test endpoints
curl http://localhost:3000/write-temp  # ✓ Allowed (tmpfs)
curl http://localhost:3000/write-root  # ✗ Blocked (read-only)
```

### Minimal Attack Surface
```bash
cd 02-minimal-attack-surface
docker-compose up -d

# Try to get shell in distroless (will fail - no shell!)
docker exec -it chapter-06-security_app-distroless_1 /bin/sh
# Error: OCI runtime exec failed: exec: "/bin/sh": stat /bin/sh: no such file or directory

# Compare image sizes
docker images | grep minimal
```

### Secrets Management
```bash
cd 03-secrets-management
chmod +x demo-secrets.sh
./demo-secrets.sh

# Secrets are in /run/secrets/, not environment
docker-compose exec app ls /run/secrets/
docker-compose exec app cat /run/secrets/db_password
```

## Security Best Practices Demonstrated

### 1. Run as Non-Root User

```dockerfile
# Create dedicated user
RUN addgroup -g 1000 appuser && \
    adduser -D -u 1000 -G appuser appuser

USER appuser
```

**Why:** Root inside container = root on host (same UID). Non-root limits damage.

### 2. Read-Only Filesystem

```yaml
services:
  app:
    read_only: true
    tmpfs:
      - /tmp:size=10M
```

**Why:** Prevents attackers from modifying binaries or installing malware.

### 3. Drop Linux Capabilities

```yaml
services:
  app:
    cap_drop:
      - ALL  # Remove all capabilities
    cap_add:
      - NET_BIND_SERVICE  # Only add what's needed
```

**Why:** Limits what privileged operations containers can perform.

### 4. No New Privileges

```yaml
services:
  app:
    security_opt:
      - no-new-privileges:true
```

**Why:** Prevents privilege escalation via setuid binaries.

### 5. Secrets Management

```yaml
services:
  app:
    secrets:
      - db_password
    environment:
      - DB_PASSWORD_FILE=/run/secrets/db_password

secrets:
  db_password:
    file: ./secrets/db_password.txt
```

**Why:** Never expose secrets in env vars or image layers.

## Security Comparison

### Before vs After Hardening

| Aspect | Before | After |
|--------|--------|-------|
| User | root (uid=0) | appuser (uid=1000) |
| Filesystem | writable | read-only + tmpfs |
| Capabilities | 14 capabilities | 0-1 capabilities |
| Shell | /bin/bash, /bin/sh | None (distroless) |
| Packages | 100+ packages | 5-10 packages |
| Image size | 200MB+ | 20-50MB |
| Attack surface | Large | Minimal |

## Common Security Vulnerabilities

### ❌ DON'T DO THIS

```dockerfile
# Running as root
FROM ubuntu
COPY app /app
CMD ["/app"]  # Runs as root!

# Secrets in environment
ENV DB_PASSWORD=SuperSecret123  # ← Visible in docker inspect!

# Secrets in image layers
COPY secrets.txt /app/  # ← Stays in image forever!

# Writable filesystem
# (Default - allows malware installation)

# All capabilities enabled
# (Default - allows privileged operations)
```

### ✅ DO THIS INSTEAD

```dockerfile
# Multi-stage minimal image
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

FROM gcr.io/distroless/nodejs18-debian11:nonroot
COPY --from=builder /app/node_modules ./node_modules
COPY --chown=nonroot:nonroot . .
CMD ["server.js"]
```

```yaml
# docker-compose.yml
services:
  app:
    build: .
    read_only: true
    tmpfs:
      - /tmp:size=10M
    secrets:
      - db_password
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
```

## Testing Security

### Verify Non-Root User

```bash
docker run --rm your-image id
# Should show uid=1000 or similar, NOT uid=0
```

### Verify Read-Only Filesystem

```bash
docker exec container touch /test.txt
# Should fail with "Read-only file system"
```

### Verify Capabilities

```bash
docker exec container cat /proc/self/status | grep Cap
# Should show mostly zeros (few capabilities)
```

### Verify No Shell

```bash
docker exec container /bin/sh
# Should fail if using distroless
```

## Security Scanning

### Scan Images for Vulnerabilities

```bash
# Using Trivy
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image your-image:latest

# Using Snyk
snyk container test your-image:latest

# Using Docker Scout
docker scout cves your-image:latest
```

### Fix Common Vulnerabilities

```dockerfile
# Keep base images updated
FROM node:18-alpine  # ← Use specific version
# Not: FROM node:latest

# Update packages
RUN apk update && apk upgrade && \
    apk add --no-cache nodejs=~18 && \
    rm -rf /var/cache/apk/*
```

## Production Security Checklist

Before deploying to production:

- [ ] Run as non-root user
- [ ] Use read-only filesystem
- [ ] Drop all capabilities, add only required ones
- [ ] Enable `no-new-privileges`
- [ ] Use secrets for sensitive data
- [ ] Scan for vulnerabilities (Trivy/Snyk)
- [ ] Use minimal base images (Alpine/Distroless)
- [ ] Set resource limits (memory/CPU)
- [ ] Enable logging and monitoring
- [ ] Implement health checks
- [ ] Use specific image tags (not `latest`)
- [ ] Sign images (Docker Content Trust)
- [ ] Limit network exposure
- [ ] Implement AppArmor/SELinux profiles

## Advanced Security

### AppArmor Profile

```yaml
services:
  app:
    security_opt:
      - apparmor=docker-default
```

### SELinux Context

```yaml
services:
  app:
    security_opt:
      - label=type:container_t
```

### Seccomp Profile

```yaml
services:
  app:
    security_opt:
      - seccomp=./seccomp-profile.json
```

Example seccomp profile (block dangerous syscalls):
```json
{
  "defaultAction": "SCMP_ACT_ERRNO",
  "architectures": ["SCMP_ARCH_X86_64"],
  "syscalls": [
    {
      "names": ["read", "write", "open", "close", "stat"],
      "action": "SCMP_ACT_ALLOW"
    }
  ]
}
```

## Key Takeaways

✅ **Defense in depth** - Multiple layers of security
✅ **Principle of least privilege** - Minimal permissions needed
✅ **Immutable infrastructure** - Read-only filesystems
✅ **Secrets management** - Never in env vars or images
✅ **Minimal attack surface** - Fewer packages = fewer vulnerabilities
✅ **Regular scanning** - Catch vulnerabilities early
✅ **Non-root by default** - Limit blast radius

## Further Reading

- Docker Security Best Practices: https://docs.docker.com/engine/security/
- CIS Docker Benchmark: https://www.cisecurity.org/benchmark/docker
- NIST Container Security: https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-190.pdf

**Reference:** Docker Field Manual, Chapter 6, Pages 145-185

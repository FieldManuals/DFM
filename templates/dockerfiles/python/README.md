# Production Python Dockerfile Template

**For Flask, FastAPI, Django, and general Python applications**

## Features

✅ **Multi-stage build** - Separates build dependencies from runtime
✅ **Virtual environment** - Isolated Python packages
✅ **Slim base image** - Python 3.11 slim variant (~150MB)
✅ **Non-root user** - Security best practice
✅ **Gunicorn** - Production WSGI server
✅ **Health checks** - Container health monitoring
✅ **Layer optimization** - Fast rebuilds with caching

## Quick Start

### Flask Application

```bash
# Build
docker build -t python-app:1.0 .

# Run
docker run -d --name app -p 8000:8000 python-app:1.0

# Test
curl http://localhost:8000
curl http://localhost:8000/health
```

### With Environment Variables

```bash
docker run -d --name app \
  -p 8000:8000 \
  -e ENVIRONMENT=production \
  -e DATABASE_URL=postgresql://user:pass@db:5432/myapp \
  python-app:1.0
```

## Dockerfile Breakdown

### Stage 1: Builder

```dockerfile
FROM python:3.11-slim as base
```
- Slim variant (150MB vs 900MB full image)
- Python 3.11 for latest features

```dockerfile
FROM base as builder
RUN apt-get update && apt-get install -y gcc
```
- Install build tools (gcc for compiling packages)
- Only in builder stage

```dockerfile
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
```
- Create isolated virtual environment
- Ensures clean package installation

```dockerfile
RUN pip install -r requirements.txt
```
- Install all Python dependencies
- Compiled in builder, copied to production

### Stage 2: Production

```dockerfile
FROM base as production
COPY --from=builder /opt/venv /opt/venv
```
- Start fresh from slim base
- Copy only the virtual environment
- No build tools in final image

```dockerfile
RUN useradd -m -u 1000 appuser
USER appuser
```
- Never run as root
- Creates dedicated user with UID 1000

```dockerfile
CMD ["gunicorn", "--bind", "0.0.0.0:8000", ...]
```
- Production WSGI server
- 4 workers, 2 threads per worker
- Access and error logging enabled

## Framework-Specific Configurations

### Flask (Default)

```python
# app.py
from flask import Flask
app = Flask(__name__)

# requirements.txt
Flask==3.0.0
gunicorn==21.2.0

# Dockerfile CMD
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "app:app"]
```

### FastAPI

```python
# app.py (change to main.py)
from fastapi import FastAPI
app = FastAPI()

# requirements.txt
fastapi==0.104.1
uvicorn[standard]==0.24.0

# Dockerfile CMD (replace Gunicorn line)
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]
```

### Django

```python
# requirements.txt
Django==4.2.7
gunicorn==21.2.0
psycopg2-binary==2.9.9

# Dockerfile - add migration step
CMD ["sh", "-c", "python manage.py migrate && gunicorn --bind 0.0.0.0:8000 myproject.wsgi:application"]
```

## Image Size Comparison

```bash
# Without multi-stage
FROM python:3.11
# Result: 900MB+

# With slim base only
FROM python:3.11-slim
# Result: 400MB

# With multi-stage + slim
FROM python:3.11-slim as builder
FROM python:3.11-slim as production
# Result: 180-250MB (depending on dependencies)

# With Alpine (advanced)
FROM python:3.11-alpine
# Result: 80-150MB
# Note: Requires compilation of C extensions, slower builds
```

## Development vs Production

### Development (docker-compose.yml)

```yaml
version: '3.8'
services:
  app:
    build:
      context: .
      target: base  # Stop at base stage
    volumes:
      - .:/app  # Mount code for hot reload
    environment:
      - FLASK_DEBUG=1
      - FLASK_ENV=development
    command: python app.py  # Use Flask dev server
    ports:
      - "8000:8000"
```

### Production

```yaml
version: '3.8'
services:
  app:
    build:
      context: .
      target: production  # Full build
    environment:
      - ENVIRONMENT=production
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 3s
      retries: 3
    ports:
      - "8000:8000"
```

## Optimization Tips

### 1. Order Layers by Change Frequency

```dockerfile
COPY requirements.txt .     # ← Changes rarely
RUN pip install -r requirements.txt
COPY . .                    # ← Changes often
```

### 2. Use .dockerignore

```
__pycache__/
*.pyc
.git/
.pytest_cache/
```

### 3. Pin Versions

```txt
# Good
Flask==3.0.0
requests==2.31.0

# Bad
Flask
requests
```

### 4. Combine RUN Commands

```dockerfile
# Better
RUN apt-get update && \
    apt-get install -y gcc && \
    rm -rf /var/lib/apt/lists/*

# Worse (more layers)
RUN apt-get update
RUN apt-get install -y gcc
RUN rm -rf /var/lib/apt/lists/*
```

### 5. Use Build Cache

```bash
# First build: 5 minutes
docker build -t app .

# Code change only: 30 seconds (cached layers)
docker build -t app .

# Requirements change: 2 minutes (rebuild from requirements)
docker build -t app .
```

## Database Integration

### PostgreSQL

```python
# requirements.txt
psycopg2-binary==2.9.9
SQLAlchemy==2.0.23

# app.py
import os
from sqlalchemy import create_engine

DATABASE_URL = os.getenv('DATABASE_URL', 'postgresql://user:pass@localhost/db')
engine = create_engine(DATABASE_URL)

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
      DATABASE_URL: postgresql://postgres:secret@db:5432/myapp
    depends_on:
      - db

volumes:
  postgres_data:
```

### Redis Cache

```python
# requirements.txt
redis==5.0.1

# app.py
import redis
import os

REDIS_URL = os.getenv('REDIS_URL', 'redis://localhost:6379')
cache = redis.from_url(REDIS_URL)

# docker-compose.yml
services:
  redis:
    image: redis:7-alpine
    
  app:
    build: .
    environment:
      REDIS_URL: redis://redis:6379
    depends_on:
      - redis
```

## Security Best Practices

### 1. Non-Root User ✅
```dockerfile
USER appuser
```

### 2. Read-Only Root Filesystem

```dockerfile
# In docker-compose.yml or docker run
read_only: true
tmpfs:
  - /tmp
  - /app/logs
```

### 3. Security Scanning

```bash
# Scan for vulnerabilities
docker scout cves python-app:1.0

# Or use Trivy
trivy image python-app:1.0
```

### 4. Minimal Base Image

```dockerfile
# Slim variant has fewer packages = smaller attack surface
FROM python:3.11-slim
```

### 5. No Secrets in Image

```bash
# Bad
ENV DATABASE_PASSWORD=secret

# Good - use runtime environment
docker run -e DATABASE_PASSWORD=secret app
```

## Common Patterns

### Async Workers (Celery)

```dockerfile
# Dockerfile.worker
FROM python-app:1.0

CMD ["celery", "-A", "app.celery", "worker", "--loglevel=info"]
```

### Database Migrations

```dockerfile
# Dockerfile with migrations
CMD ["sh", "-c", "alembic upgrade head && gunicorn app:app"]
```

### Static Files (Django)

```dockerfile
# Multi-stage with static collection
FROM production as static
RUN python manage.py collectstatic --noinput

FROM nginx:alpine
COPY --from=static /app/staticfiles /usr/share/nginx/html/static
```

## Troubleshooting

### Import errors?

```bash
# Verify packages installed
docker run -it --rm python-app:1.0 pip list

# Check virtual environment path
docker run -it --rm python-app:1.0 which python
# Should show: /opt/venv/bin/python
```

### Permission denied?

```bash
# Check file ownership
docker run -it --rm python-app:1.0 ls -la /app

# Should show: appuser appuser
```

### Slow builds?

```bash
# Use BuildKit
export DOCKER_BUILDKIT=1
docker build -t python-app:1.0 .

# Or
docker buildx build -t python-app:1.0 .
```

### Image too large?

```bash
# Analyze layers
docker history python-app:1.0

# Use dive tool
dive python-app:1.0
```

## Testing

### Test Build Locally

```bash
# Build
docker build -t python-app:test .

# Run tests
docker run --rm python-app:test pytest

# Interactive testing
docker run -it --rm python-app:test sh
```

### Automated Testing

```yaml
# .github/workflows/test.yml
- name: Build and test
  run: |
    docker build -t app .
    docker run --rm app pytest
```

## Production Deployment

### Docker Compose

```yaml
version: '3.8'
services:
  app:
    image: registry.example.com/python-app:${VERSION}
    deploy:
      replicas: 3
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
    environment:
      - ENVIRONMENT=production
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
```

### Kubernetes

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: python-app
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: app
        image: registry.example.com/python-app:1.0.0
        resources:
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
```

## Complete Example

See the `example-app/` directory for a complete FastAPI application with:
- Database integration (PostgreSQL)
- Redis caching
- Celery workers
- Docker Compose setup
- CI/CD pipeline
- Kubernetes manifests

## Key Takeaways

✅ Multi-stage builds reduce image size by 70%+
✅ Virtual environments isolate dependencies
✅ Non-root users improve security
✅ Gunicorn provides production-grade WSGI serving
✅ Health checks enable container orchestration
✅ Layer caching speeds up rebuilds dramatically

**Reference:** Docker Field Manual, Chapter 4, Pages 92-98

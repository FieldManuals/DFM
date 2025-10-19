# Python Flask Application

A simple Flask web application demonstrating proper Dockerfile practices.

## What This Demonstrates

- **Layer caching** - Requirements installed before code copy
- **Non-root user** - Security best practice
- **Health checks** - Container health monitoring
- **Environment variables** - Flexible configuration
- **Slim base image** - Smaller image size

## Project Structure

```
02-python-flask-app/
├── Dockerfile
├── app.py
├── requirements.txt
└── README.md
```

## Build and Run

### Build the image

```bash
docker build -t my-flask-app:1.0 .
```

### Run with defaults

```bash
docker run -d --name flask-app -p 5000:5000 my-flask-app:1.0
```

### Run with environment variables

```bash
docker run -d --name flask-app \
  -p 5000:5000 \
  -e ENVIRONMENT=production \
  -e APP_VERSION=1.0.0 \
  my-flask-app:1.0
```

## Test It

```bash
# Check the app
curl http://localhost:5000

# Check health endpoint
curl http://localhost:5000/health

# View logs
docker logs flask-app

# Check health status
docker inspect flask-app --format='{{.State.Health.Status}}'
```

## Dockerfile Breakdown

### 1. Base Image
```dockerfile
FROM python:3.11-slim
```
- Uses slim variant (smaller than full python image)
- Python 3.11 for latest features

### 2. Working Directory
```dockerfile
WORKDIR /app
```
- All subsequent commands run in /app
- Keeps container organized

### 3. Dependencies First
```dockerfile
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
```
- Copy requirements before code
- Leverages Docker layer caching
- If requirements unchanged, layer reused
- `--no-cache-dir` reduces image size

### 4. Copy Application Code
```dockerfile
COPY app.py .
```
- Copied after dependencies
- Code changes don't invalidate dependency layer

### 5. Security: Non-Root User
```dockerfile
RUN useradd -m appuser && chown -R appuser:appuser /app
USER appuser
```
- Never run as root in production
- Creates dedicated user
- Sets file ownership

### 6. Expose Port
```dockerfile
EXPOSE 5000
```
- Documents which port app uses
- Doesn't actually publish port (need -p flag)

### 7. Health Check
```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:5000/health')"
```
- Checks /health endpoint every 30s
- 3 second timeout
- 5 second start period
- 3 retries before marking unhealthy

### 8. Start Command
```dockerfile
CMD ["python", "app.py"]
```
- Exec form (preferred)
- Runs as PID 1
- Handles signals properly

## Development vs Production

### Development

```bash
# Mount code as volume for live reload
docker run -d --name flask-dev \
  -p 5000:5000 \
  -v $(pwd)/app.py:/app/app.py \
  -e FLASK_DEBUG=1 \
  my-flask-app:1.0
```

### Production

```bash
# No volume mounts, no debug
docker run -d --name flask-prod \
  -p 5000:5000 \
  -e ENVIRONMENT=production \
  --restart unless-stopped \
  --memory="512m" \
  --cpus="0.5" \
  my-flask-app:1.0
```

## Best Practices Demonstrated

✅ **Slim base image** - Smaller attack surface
✅ **Layer caching** - Faster builds
✅ **Non-root user** - Security
✅ **Health checks** - Reliability
✅ **No cache** - Smaller image
✅ **Specific Python version** - Reproducibility
✅ **Environment variables** - Flexibility

## Common Issues

### Port already in use?
```bash
# Use different port
docker run -d -p 5001:5000 my-flask-app:1.0
```

### Container starts then exits?
```bash
# Check logs
docker logs flask-app

# Run interactively to debug
docker run -it --rm my-flask-app:1.0 sh
```

### Permission denied?
```bash
# Ensure proper ownership in Dockerfile
# Already handled with: chown -R appuser:appuser /app
```

## Optimization Tips

### Multi-stage build (if compiling packages)
```dockerfile
FROM python:3.11-slim as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

FROM python:3.11-slim
WORKDIR /app
COPY --from=builder /root/.local /root/.local
COPY app.py .
ENV PATH=/root/.local/bin:$PATH
CMD ["python", "app.py"]
```

### .dockerignore file
```
__pycache__/
*.pyc
*.pyo
*.pyd
.Python
env/
venv/
.pytest_cache/
.git/
```

## Cleanup

```bash
# Stop and remove container
docker stop flask-app
docker rm flask-app

# Remove image
docker rmi my-flask-app:1.0
```

**Reference:** Docker Field Manual, Chapter 4, Pages 85-92

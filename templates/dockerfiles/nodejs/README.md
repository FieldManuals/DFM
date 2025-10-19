# Node.js Dockerfile Template

Production-ready Dockerfile for Node.js applications with security best practices.

## Features

- ✅ Multi-stage build for smaller images
- ✅ Non-root user for security
- ✅ Alpine Linux for minimal size
- ✅ Proper signal handling with dumb-init
- ✅ Health check included
- ✅ Layer caching optimization
- ✅ Production dependencies only

## Usage

### 1. Copy Dockerfile to your project

```bash
cp Dockerfile /path/to/your/nodejs/project/
```

### 2. Customize for your application

Edit these lines:

```dockerfile
# If using different port
EXPOSE 3000  # Change to your port

# If using different start command
CMD ["node", "server.js"]  # Change to your entry point

# If using TypeScript (uncomment in build stage)
RUN npm run build
```

### 3. Build the image

```bash
docker build -t my-nodejs-app:latest .
```

### 4. Run the container

```bash
docker run -d \
  --name my-app \
  -p 3000:3000 \
  -e NODE_ENV=production \
  my-nodejs-app:latest
```

## File Structure

Your project should have:

```
your-app/
├── Dockerfile
├── .dockerignore
├── package.json
├── package-lock.json
├── server.js (or app.js, index.js)
├── healthcheck.js (optional)
└── src/
    └── ... your code
```

## .dockerignore

Create a `.dockerignore` file:

```
node_modules
npm-debug.log
.git
.gitignore
README.md
.env
.env.local
.DS_Store
coverage
.vscode
.idea
*.log
dist
build
```

## Health Check

Create `healthcheck.js`:

```javascript
const http = require('http');

const options = {
  host: 'localhost',
  port: 3000,
  path: '/health',
  timeout: 2000
};

const request = http.request(options, (res) => {
  console.log(`STATUS: ${res.statusCode}`);
  process.exit(res.statusCode === 200 ? 0 : 1);
});

request.on('error', (err) => {
  console.log('ERROR:', err);
  process.exit(1);
});

request.end();
```

And add health endpoint to your app:

```javascript
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy' });
});
```

## Environment Variables

```bash
# Development
docker run -e NODE_ENV=development my-app

# Production with custom vars
docker run \
  -e NODE_ENV=production \
  -e PORT=3000 \
  -e DB_HOST=database \
  -e DB_PORT=5432 \
  my-app
```

## Docker Compose Example

```yaml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - PORT=3000
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "node", "healthcheck.js"]
      interval: 30s
      timeout: 3s
      retries: 3
```

## Build Arguments

Add to Dockerfile:

```dockerfile
ARG NODE_VERSION=18
FROM node:${NODE_VERSION}-alpine AS builder
```

Build with custom Node version:

```bash
docker build --build-arg NODE_VERSION=20 -t my-app .
```

## Security Best Practices

✅ **Non-root user**: Runs as user `nodejs` (UID 1001)
✅ **Minimal base**: Uses Alpine Linux
✅ **No unnecessary packages**: Production dependencies only
✅ **Proper signal handling**: Uses dumb-init
✅ **Regular updates**: Use latest LTS Node.js version
✅ **Scan for vulnerabilities**: `docker scan my-app`

## Size Optimization

```bash
# Check image size
docker images my-nodejs-app

# Typical sizes:
# - With this template: 120-150 MB
# - Without multi-stage: 900+ MB
# - With full Node (not Alpine): 1+ GB
```

## Troubleshooting

### Permission denied errors

Make sure files are owned by nodejs user:

```dockerfile
COPY --chown=nodejs:nodejs . .
```

### npm install fails

Check your package-lock.json is committed:

```bash
npm ci  # Requires package-lock.json
```

### Healthcheck fails

Test healthcheck locally:

```bash
docker run my-app node healthcheck.js
```

## Advanced: TypeScript Support

For TypeScript projects:

```dockerfile
# Build stage - add this
RUN npm ci && \
    npm run build && \
    npm ci --only=production

# Production stage - copy built files
COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist

# Update CMD
CMD ["node", "dist/server.js"]
```

## References

- [Node.js Docker Best Practices](https://github.com/nodejs/docker-node/blob/main/docs/BestPractices.md)
- [Docker Official Images - Node](https://hub.docker.com/_/node)
- [dumb-init Documentation](https://github.com/Yelp/dumb-init)

---

**Book Reference:** Docker Field Manual, Chapter 6: Advanced Docker Usage

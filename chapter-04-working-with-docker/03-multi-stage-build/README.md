# Multi-Stage Build Example (Node.js + TypeScript)

Demonstrates Docker multi-stage builds for creating optimized production images.

## What Is a Multi-Stage Build?

Multi-stage builds use multiple `FROM` statements in a single Dockerfile. Each stage can copy artifacts from previous stages, allowing you to:

- Separate build dependencies from runtime dependencies
- Create smaller production images
- Keep build tools out of production
- Improve security by reducing attack surface

## The Problem Multi-Stage Solves

### Without Multi-Stage (Bad)
```dockerfile
FROM node:18
COPY . .
RUN npm install  # Installs ALL dependencies including devDependencies
RUN npm run build
CMD ["node", "dist/index.js"]

# Result: 1.2 GB image with TypeScript, build tools, etc.
```

### With Multi-Stage (Good)
```dockerfile
FROM node:18 AS builder
# Build stage with all dev tools

FROM node:18
# Production stage with only runtime dependencies

# Result: 450 MB image with ONLY what's needed to run
```

## Project Structure

```
03-multi-stage-build/
├── Dockerfile          # Multi-stage build
├── package.json        # Dependencies
├── tsconfig.json       # TypeScript config
├── src/
│   └── index.ts       # Source code
└── README.md
```

## Build and Run

### Build the image

```bash
docker build -t multi-stage-app:1.0 .
```

### Check image size

```bash
docker images multi-stage-app:1.0

# Compare to single-stage approach:
# Single-stage: ~1.2 GB
# Multi-stage:  ~450 MB
# Savings:      ~750 MB (62% smaller!)
```

### Run the container

```bash
docker run -d --name app -p 3000:3000 multi-stage-app:1.0
```

### Test it

```bash
curl http://localhost:3000
curl http://localhost:3000/health
```

## Dockerfile Breakdown

### Stage 1: Builder (Build Environment)

```dockerfile
FROM node:18-alpine AS builder
```
- Named stage: `builder`
- Has all build tools
- Will be discarded in final image

```dockerfile
RUN npm ci
COPY . .
RUN npm run build
```
- Install ALL dependencies (including devDependencies)
- Compile TypeScript to JavaScript
- Creates `dist/` directory

### Stage 2: Production (Runtime Environment)

```dockerfile
FROM node:18-alpine
```
- Fresh start, no build artifacts
- Only runtime needed

```dockerfile
RUN npm ci --only=production
```
- Install ONLY production dependencies
- No TypeScript, no build tools

```dockerfile
COPY --from=builder /app/dist ./dist
```
- **Magic line!** Copy built code from `builder` stage
- Only compiled JavaScript, no TypeScript source

### Result

Final image contains:
✅ Node.js runtime
✅ Production dependencies
✅ Compiled JavaScript

Final image DOESN'T contain:
❌ TypeScript compiler
❌ Dev dependencies
❌ Source .ts files
❌ Build tools

## Size Comparison

```bash
# Build single-stage version (for comparison)
docker build -f Dockerfile.single -t single-stage-app:1.0 .

# Compare sizes
docker images | grep stage-app

# Results:
# single-stage-app    1.0    ...    1.2GB
# multi-stage-app     1.0    ...    450MB
```

## Inspect What's Inside

### Check builder stage contents

```bash
# Build only up to builder stage
docker build --target builder -t builder-stage .

# Run it interactively
docker run -it --rm builder-stage sh

# Inside container:
ls -la            # See source files
ls node_modules/  # See ALL dependencies including dev
```

### Check production stage contents

```bash
docker run -it --rm multi-stage-app:1.0 sh

# Inside container:
ls -la            # Only dist/ and package.json
ls node_modules/  # Only production dependencies
```

## Best Practices Demonstrated

### 1. Name Your Stages
```dockerfile
FROM node:18 AS builder  # ← Named stage
```
Makes `COPY --from=builder` clear and maintainable

### 2. Use Alpine Images
```dockerfile
FROM node:18-alpine  # ← Alpine variant
```
Smaller base image (100MB vs 900MB)

### 3. Layer Caching
```dockerfile
COPY package*.json ./
RUN npm ci
COPY . .  # ← After dependencies installed
```
Code changes don't invalidate dependency layer

### 4. Clean NPM Cache
```dockerfile
RUN npm ci --only=production && \
    npm cache clean --force
```
Reduces image size

### 5. Non-Root User
```dockerfile
USER nodejs
```
Security best practice

## Advanced: Multi-Stage for Multiple Outputs

```dockerfile
# Common base
FROM node:18-alpine AS base
WORKDIR /app
COPY package*.json ./

# Dependencies
FROM base AS dependencies
RUN npm ci

# Development
FROM dependencies AS development
COPY . .
CMD ["npm", "run", "dev"]

# Build
FROM dependencies AS builder
COPY . .
RUN npm run build

# Production
FROM base AS production
RUN npm ci --only=production
COPY --from=builder /app/dist ./dist
CMD ["node", "dist/index.js"]
```

### Build specific stage

```bash
# Development image
docker build --target development -t app:dev .

# Production image (default)
docker build -t app:prod .
```

## Real-World Example: React App

```dockerfile
# Build stage
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build
# Creates /app/build with static files

# Production stage with Nginx
FROM nginx:alpine
COPY --from=builder /app/build /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]

# Result: Nginx serving static files
# No Node.js in final image!
```

## Troubleshooting

### Build fails at stage 2?

```bash
# Test builder stage independently
docker build --target builder -t test-builder .
docker run -it --rm test-builder sh
```

### Missing files in production?

```bash
# Check what was copied
docker run -it --rm multi-stage-app:1.0 sh
ls -la
ls dist/
```

### Still too large?

```bash
# Analyze layers
docker history multi-stage-app:1.0

# Use dive tool for deep analysis
dive multi-stage-app:1.0
```

## Performance Benefits

### Build time

- **First build**: Slower (builds everything)
- **Subsequent builds**: Fast (layer caching)
- **Code changes**: Only rebuilds from changed layer

### Image pull time

- Smaller image = Faster deployment
- 450MB vs 1.2GB = 3x faster pull

### Security

- Fewer packages = Smaller attack surface
- No build tools = Less vulnerability exposure

## Cleanup

```bash
# Stop and remove container
docker stop app && docker rm app

# Remove images
docker rmi multi-stage-app:1.0

# Remove builder stages (cached)
docker builder prune
```

## Key Takeaways

✅ Multi-stage builds create production-optimized images
✅ Separate build environment from runtime environment
✅ Dramatically reduces image size (often 50-70%)
✅ Improves security by excluding unnecessary tools
✅ Faster deployment due to smaller images
✅ Better layer caching = Faster rebuilds

**Reference:** Docker Field Manual, Chapter 4, Pages 92-98

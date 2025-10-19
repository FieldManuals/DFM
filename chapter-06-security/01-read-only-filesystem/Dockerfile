# Hardened Dockerfile with read-only filesystem
FROM node:18-alpine

# Create app directory
WORKDIR /app

# Create temporary directory for writable storage
RUN mkdir -p /tmp/app-cache && \
    chown -R node:node /tmp/app-cache

# Copy application files
COPY package*.json ./
RUN npm ci --only=production && \
    npm cache clean --force

COPY --chown=node:node . .

# Switch to non-root user
USER node

# Expose port
EXPOSE 3000

# Run with read-only filesystem
# Writable tmpfs will be mounted at runtime
CMD ["node", "server.js"]

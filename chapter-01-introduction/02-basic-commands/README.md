# Chapter 1: Basic Docker Commands

Master the essential Docker commands you'll use every day.

## Commands Covered

### Image Management
- `docker pull` - Download images
- `docker images` - List local images
- `docker inspect` - Detailed image information
- `docker history` - View image layers
- `docker rmi` - Remove images

### Container Lifecycle
- `docker run` - Create and start container
- `docker ps` - List containers
- `docker logs` - View container output
- `docker stop` - Stop container
- `docker start` - Start stopped container
- `docker restart` - Restart container
- `docker rm` - Remove container

### Interactive Mode
- `docker run -it` - Interactive container
- `docker exec -it` - Execute command in running container

## Quick Start

```bash
# Make script executable
chmod +x commands.sh

# Run the demo script
./commands.sh
```

## Manual Command Walkthrough

### 1. Pull and Inspect an Image

```bash
# Download nginx alpine image
docker pull nginx:alpine

# View local images
docker images

# Inspect the image
docker inspect nginx:alpine

# See how it was built
docker history nginx:alpine
```

### 2. Run a Container

```bash
# Run nginx in background on port 8080
docker run -d --name webserver -p 8080:80 nginx:alpine

# Check it's running
docker ps

# Test it
curl http://localhost:8080

# View logs
docker logs webserver
```

### 3. Interact with Running Container

```bash
# Execute command in running container
docker exec -it webserver sh

# Inside container:
ls /usr/share/nginx/html/
cat /etc/nginx/nginx.conf
exit
```

### 4. Container Lifecycle

```bash
# Stop container
docker stop webserver

# Verify it's stopped
docker ps -a

# Start it again
docker start webserver

# Restart it
docker restart webserver
```

### 5. Cleanup

```bash
# Stop and remove container
docker stop webserver
docker rm webserver

# Remove image
docker rmi nginx:alpine
```

## Common Flags Explained

### docker run flags

```bash
-d, --detach              Run in background
-it                       Interactive terminal
--name                    Give container a name
-p, --publish             Publish port (host:container)
-v, --volume              Mount volume
-e, --env                 Set environment variable
--rm                      Remove container when it exits
--restart                 Restart policy
```

### docker ps flags

```bash
-a, --all                 Show all containers
-q, --quiet               Only show IDs
-f, --filter              Filter output
--format                  Pretty-print using template
```

## Pro Tips

### Always use --rm for one-off containers
```bash
# Container auto-removes when done
docker run --rm ubuntu:22.04 echo "Hello!"
```

### Name your containers
```bash
# Easier than remembering IDs
docker run -d --name db postgres:15
docker logs db
docker stop db
```

### Use specific tags, not "latest"
```bash
# Good - specific version
docker pull nginx:1.25-alpine

# Bad - ambiguous
docker pull nginx:latest
```

### Clean up regularly
```bash
# Remove stopped containers
docker container prune

# Remove unused images
docker image prune

# Remove everything unused
docker system prune
```

## Common Patterns

### Check if container is healthy
```bash
docker ps --filter "name=webserver"
docker inspect webserver --format='{{.State.Status}}'
```

### Follow logs in real-time
```bash
docker logs -f webserver
```

### Copy files to/from container
```bash
# Copy TO container
docker cp index.html webserver:/usr/share/nginx/html/

# Copy FROM container
docker cp webserver:/etc/nginx/nginx.conf ./nginx.conf
```

### Resource usage
```bash
# Current stats
docker stats --no-stream

# Continuous monitoring
docker stats
```

## Troubleshooting

### Container won't start?
```bash
# Check logs
docker logs container-name

# Inspect for errors
docker inspect container-name
```

### Port already in use?
```bash
# Use different host port
docker run -d -p 8081:80 nginx:alpine

# Or find what's using the port
lsof -i :8080
```

### Container disappeared?
```bash
# It might have exited
docker ps -a

# Check exit code
docker inspect container-name --format='{{.State.ExitCode}}'
```

## Quick Reference Card

```
LIFECYCLE           INFORMATION         CLEANUP
---------           -----------         -------
docker run          docker ps           docker rm
docker stop         docker logs         docker rmi
docker start        docker inspect      docker prune
docker restart      docker stats        
docker pause        docker top          
docker unpause      docker port         
```

**Reference:** Docker Field Manual, Chapter 1, Pages 12-17

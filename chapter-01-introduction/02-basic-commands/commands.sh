#!/bin/bash
# Chapter 1: Basic Docker Commands
# These commands introduce you to Docker's CLI and basic operations

echo "=== Docker Installation Verification ==="

# Check Docker version
docker --version

# Get detailed system information
docker system info

echo ""
echo "=== Working with Images ==="

# Pull an image from Docker Hub
docker pull nginx:alpine

# List all local images
docker images

# Inspect an image (JSON output)
docker inspect nginx:alpine

# View image build history
docker history nginx:alpine

echo ""
echo "=== Creating and Running Containers ==="

# Run a container in detached mode
docker run -d --name my-nginx -p 8080:80 nginx:alpine

# List running containers
docker ps

# List all containers (including stopped)
docker ps -a

# View container logs
docker logs my-nginx

# View real-time container stats
docker stats --no-stream my-nginx

echo ""
echo "=== Container Lifecycle ==="

# Stop a container
docker stop my-nginx

# Start a stopped container
docker start my-nginx

# Restart a container
docker restart my-nginx

# Pause a container
docker pause my-nginx

# Unpause a container
docker unpause my-nginx

# Stop container
docker stop my-nginx

# Remove container
docker rm my-nginx

echo ""
echo "=== Interactive Containers ==="

# Run an interactive container
echo "Starting interactive Ubuntu container..."
echo "Type 'exit' to leave the container"
docker run -it --name my-ubuntu ubuntu:22.04 bash

echo ""
echo "=== Cleanup ==="

# Remove stopped containers
docker container prune -f

# Remove unused images
docker image prune -f

# Remove everything unused
docker system prune -f

echo ""
echo "=== Quick Reference ==="
echo "docker run       - Create and start container"
echo "docker ps        - List running containers"
echo "docker ps -a     - List all containers"
echo "docker images    - List images"
echo "docker logs      - View container logs"
echo "docker stop      - Stop container"
echo "docker rm        - Remove container"
echo "docker rmi       - Remove image"
echo "docker system    - System-wide commands"

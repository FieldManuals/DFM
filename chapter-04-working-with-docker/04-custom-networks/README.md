# Chapter 4: Custom Networks Example

Demonstrates Docker networking concepts: bridge, host, none, and custom networks.

## What This Demonstrates

- Creating custom bridge networks
- Container communication by name (DNS)
- Network isolation
- Connecting containers to multiple networks
- Inspecting network configuration

## Quick Start

```bash
# Run the demo script
./network-demo.sh
```

## Manual Walkthrough

### 1. Create Custom Networks

```bash
# Create frontend network
docker network create frontend

# Create backend network  
docker network create backend

# List networks
docker network ls
```

### 2. Run Containers on Networks

```bash
# Database on backend network
docker run -d --name db \
  --network backend \
  -e POSTGRES_PASSWORD=secret \
  postgres:15-alpine

# API on both networks (bridge between frontend/backend)
docker run -d --name api \
  --network backend \
  nginx:alpine

# Connect API to frontend too
docker network connect frontend api

# Web frontend on frontend network
docker run -d --name web \
  --network frontend \
  nginx:alpine
```

### 3. Test Connectivity

```bash
# Web can reach API (same network)
docker exec web ping -c 2 api
# ✅ Success

# Web CANNOT reach db (different network)
docker exec web ping -c 2 db
# ❌ Fails - isolated

# API can reach db (same backend network)
docker exec api ping -c 2 db
# ✅ Success
```

## Architecture

```
 ┌─────────────────────┐
 │  frontend network   │
 │                     │
 │   ┌───┐    ┌───┐   │
 │   │web│────│api│   │
 │   └───┘    └───┘   │
 │              │      │
 └──────────────┼──────┘
                │
 ┌──────────────┼──────┐
 │              │      │
 │            ┌───┐    │
 │            │api│    │
 │            └───┘    │
 │              │      │
 │            ┌───┐    │
 │            │db │    │
 │            └───┘    │
 │                     │
 │   backend network   │
 └─────────────────────┘
```

## Network Types

### Bridge (Default)

```bash
# Containers on default bridge
docker run -d --name web nginx

# Custom bridge (recommended)
docker network create my-bridge
docker run -d --name web --network my-bridge nginx
```

**Use when:** Containers on same host need to communicate

### Host

```bash
# Container uses host network stack
docker run -d --name web --network host nginx
```

**Use when:** Maximum performance needed, port conflicts acceptable

### None

```bash
# No networking
docker run -d --name isolated --network none alpine sleep 1000
```

**Use when:** Complete isolation required

### Custom Bridge (Recommended)

```bash
# Better than default bridge
docker network create --driver bridge \
  --subnet 172.20.0.0/16 \
  --gateway 172.20.0.1 \
  my-network
```

**Advantages:**
- Automatic DNS resolution
- Better isolation
- Custom IP ranges
- User-defined

## Network Commands

```bash
# Create network
docker network create my-net

# Create with options
docker network create \
  --driver bridge \
  --subnet 192.168.100.0/24 \
  --gateway 192.168.100.1 \
  custom-net

# List networks
docker network ls

# Inspect network
docker network inspect my-net

# Connect container
docker network connect my-net container-name

# Disconnect container
docker network disconnect my-net container-name

# Remove network
docker network rm my-net

# Remove unused networks
docker network prune
```

## Real-World Example: 3-Tier App

```bash
# Create networks
docker network create public
docker network create private

# Database (private only)
docker run -d --name db \
  --network private \
  -e POSTGRES_PASSWORD=secret \
  postgres:15

# API (both networks)
docker run -d --name api \
  --network private \
  -e DATABASE_URL=postgres://postgres:secret@db:5432/app \
  myapp-api:latest
  
docker network connect public api

# Nginx (public only, reverse proxy)
docker run -d --name nginx \
  --network public \
  -p 80:80 \
  nginx:latest

# Result:
# - Internet → nginx (port 80)
# - nginx → api (internal DNS)
# - api → db (internal DNS)
# - db is NOT accessible from nginx or internet ✅
```

## Network Isolation Example

```bash
# Create isolated networks
docker network create team-a
docker network create team-b

# Team A containers
docker run -d --name team-a-db --network team-a postgres:15
docker run -d --name team-a-app --network team-a nginx

# Team B containers
docker run -d --name team-b-db --network team-b postgres:15
docker run -d --name team-b-app --network team-b nginx

# Team A can only reach Team A
docker exec team-a-app ping team-a-db  # ✅ Works
docker exec team-a-app ping team-b-db  # ❌ Fails

# Perfect isolation!
```

## DNS Resolution

```bash
# Create network
docker network create my-net

# Run containers
docker run -d --name web --network my-net nginx
docker run -d --name api --network my-net nginx
docker run -d --name db --network my-net postgres:15

# DNS works automatically
docker exec web ping api  # ✅ Resolves to API container IP
docker exec web ping db   # ✅ Resolves to DB container IP
docker exec api ping web  # ✅ Works bidirectionally

# Check DNS resolution
docker exec web nslookup api
docker exec web cat /etc/hosts
```

## Port Publishing vs Networks

```bash
# Without network (port publishing required)
docker run -d --name db -p 5432:5432 postgres:15
# Exposed to host!

# With network (no ports published)
docker run -d --name db --network my-net postgres:15
# Only accessible to containers on my-net!

# Best practice: Only publish what needs external access
docker run -d --name nginx \
  --network my-net \
  -p 80:80 \  # Only nginx published
  nginx
```

## Troubleshooting

### Can't reach container by name?

```bash
# Check they're on same network
docker inspect container1 --format='{{json .NetworkSettings.Networks}}'
docker inspect container2 --format='{{json .NetworkSettings.Networks}}'

# Use container IP as fallback
docker inspect container --format='{{.NetworkSettings.Networks.my-net.IPAddress}}'
```

### Port conflicts?

```bash
# Check what's using port
lsof -i :80

# Use different host port
docker run -p 8080:80 nginx

# Or use custom network (no port publishing needed)
docker network create my-net
docker run --network my-net nginx
```

### Network won't delete?

```bash
# Disconnect all containers first
docker network inspect my-net -f '{{range .Containers}}{{.Name}} {{end}}'
docker network disconnect my-net container-name

# Then remove
docker network rm my-net
```

## Cleanup

```bash
./cleanup.sh

# Or manually:
docker stop web api db
docker rm web api db
docker network rm frontend backend
```

**Reference:** Docker Field Manual, Chapter 4, Pages 108-118

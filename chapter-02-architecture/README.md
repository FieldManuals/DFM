# Chapter 2: Docker Architecture Examples

Demonstrations of Docker's core architecture components: **namespaces** and **cgroups**.

## What's Inside

### 1. Namespaces Demo
**File:** `01-namespaces/demo-namespaces.sh`

Demonstrates Docker's isolation mechanisms:
- **PID namespace** - Process isolation
- **Network namespace** - Network stack isolation
- **Mount namespace** - Filesystem isolation
- **UTS namespace** - Hostname isolation
- **IPC namespace** - Inter-process communication isolation
- **User namespace** - UID/GID remapping

### 2. Cgroups Demo
**File:** `02-cgroups/demo-cgroups.sh`

Demonstrates Docker's resource control:
- **CPU limits** - Throttle CPU usage
- **Memory limits** - Cap memory allocation
- **CPU shares** - Relative CPU priority
- **Block I/O limits** - Disk throughput control
- **PID limits** - Process count restrictions
- **Real-world examples** - Production configurations

## Quick Start

```bash
# Make scripts executable
chmod +x 01-namespaces/demo-namespaces.sh
chmod +x 02-cgroups/demo-cgroups.sh

# Run namespace demonstration
./01-namespaces/demo-namespaces.sh

# Run cgroups demonstration
./02-cgroups/demo-cgroups.sh
```

## Understanding Docker Architecture

### Why Namespaces Matter

```bash
# Container sees isolated process tree
docker run --rm alpine ps aux
# Only shows container processes!

# Host sees all processes
ps aux | grep alpine
# Shows container processes with host PIDs
```

**Key Insight:** Same processes, different views. This is namespace isolation!

### Why Cgroups Matter

```bash
# Without limits - can consume all resources
docker run --rm alpine stress --vm 1 --vm-bytes 8G

# With limits - prevented from hogging resources
docker run --rm --memory="512m" alpine stress --vm 1 --vm-bytes 8G
# Killed by OOM when exceeding limit
```

**Key Insight:** Cgroups prevent noisy neighbor problems in multi-tenant environments.

## Architecture Concepts Explained

### 1. Container != Virtual Machine

| Feature | Container | VM |
|---------|-----------|---|
| Isolation | Namespaces | Hypervisor |
| Resources | Cgroups | Virtual hardware |
| Startup | < 1 second | Minutes |
| Overhead | MB | GB |
| Kernel | Shared | Separate |

### 2. Layered Filesystem (UnionFS)

```bash
# View image layers
docker history alpine:latest

# Each layer is read-only
# Container adds writable layer on top
```

### 3. Copy-on-Write (CoW)

```bash
# Multiple containers share base layers
docker run -d --name app1 nginx
docker run -d --name app2 nginx
docker run -d --name app3 nginx

# All three share the same nginx image layers!
# Each only stores differences
```

## Deep Dive Examples

### Namespace Exploration

```bash
# Find namespace IDs for a container
docker run -d --name test alpine sleep 60
docker inspect test --format '{{.State.Pid}}'

# View namespaces on host (requires root)
PID=$(docker inspect test --format '{{.State.Pid}}')
ls -la /proc/$PID/ns/

# Output shows namespace types:
# net -> network namespace
# pid -> process namespace
# mnt -> mount namespace
# uts -> hostname namespace
# ipc -> IPC namespace
```

### Cgroup Inspection

```bash
# Start container with limits
docker run -d --name limited \
  --cpus="1.5" \
  --memory="512m" \
  --memory-swap="1g" \
  nginx

# View cgroup settings
docker inspect limited | jq '.[0].HostConfig'

# On Linux, inspect cgroup files
CONTAINER_ID=$(docker ps -qf name=limited)
cat /sys/fs/cgroup/memory/docker/$CONTAINER_ID/memory.limit_in_bytes
cat /sys/fs/cgroup/cpu/docker/$CONTAINER_ID/cpu.cfs_quota_us
```

## Production Patterns

### 1. Resource Guarantees

```yaml
# docker-compose.yml
services:
  web:
    image: nginx
    deploy:
      resources:
        reservations:  # Guaranteed resources
          cpus: '0.5'
          memory: 256M
        limits:        # Maximum resources
          cpus: '2.0'
          memory: 1G
```

### 2. QoS Classes

```bash
# Guaranteed (limits = reservations)
docker run --cpus="1.0" --memory="512m" --memory-reservation="512m" app

# Burstable (reservation < limits)
docker run --cpus="2.0" --memory="1g" --memory-reservation="256m" app

# Best-effort (no limits)
docker run app
```

### 3. CPU Pinning (cpuset)

```bash
# Pin container to specific CPU cores
docker run --cpuset-cpus="0,1" app

# Useful for:
# - NUMA awareness
# - Consistent performance
# - Cache locality
```

## Common Issues and Solutions

### Issue 1: OOM Killer

**Problem:** Container killed unexpectedly
```bash
docker logs myapp
# Last line: "Killed"

dmesg | grep -i oom
# Out of memory: Killed process 1234
```

**Solution:** Set appropriate memory limits
```bash
docker run --memory="1g" --memory-reservation="512m" myapp
```

### Issue 2: CPU Throttling

**Problem:** Application slow despite low host CPU
```bash
docker stats myapp
# Shows CPU% limited to 50%
```

**Solution:** Increase CPU quota
```bash
docker update --cpus="2.0" myapp
```

### Issue 3: Process Limit Reached

**Problem:** Cannot fork new processes
```bash
docker logs myapp
# fork: Resource temporarily unavailable
```

**Solution:** Increase PID limit
```bash
docker run --pids-limit=500 myapp
```

## Testing Architecture

### Verify Isolation

```bash
# Test PID isolation
docker run --rm alpine sh -c 'echo "Container PID 1: "; cat /proc/1/cmdline'

# Test network isolation
docker run --rm alpine ip addr show

# Test filesystem isolation
docker run --rm alpine df -h
```

### Verify Resource Limits

```bash
# Test memory limit
docker run --rm --memory="100m" alpine \
  sh -c 'dd if=/dev/zero of=/dev/null bs=1M count=200'
# Should be killed by OOM

# Test CPU limit
docker run --rm --cpus="0.5" alpine \
  sh -c 'time sha256sum /dev/zero' &
# Watch with docker stats - CPU capped at 50%
```

## Architecture Visualization

```
┌─────────────────────────────────────────┐
│           Docker Host (Linux)           │
│  ┌───────────────────────────────────┐  │
│  │       Linux Kernel                │  │
│  │  ┌──────────┐     ┌──────────┐   │  │
│  │  │Namespaces│     │ Cgroups  │   │  │
│  │  │(Isolation)     │(Resources)   │  │
│  │  └──────────┘     └──────────┘   │  │
│  └───────────────────────────────────┘  │
│                                          │
│  ┌──────────┐  ┌──────────┐  ┌────────┐│
│  │Container1│  │Container2│  │Container││
│  │  App A   │  │  App B   │  │  App C │││
│  │ (isolated)  │ (limited) │ (secure) ││
│  └──────────┘  └──────────┘  └────────┘│
└─────────────────────────────────────────┘
```

## Key Takeaways

✅ **Namespaces provide isolation** - Containers can't see each other
✅ **Cgroups provide resource control** - Prevent resource starvation
✅ **Containers share kernel** - Lighter than VMs, faster startup
✅ **Copy-on-Write** - Efficient storage utilization
✅ **Production-ready** - Battle-tested in large-scale deployments

## Further Reading

- Linux Namespaces: `man namespaces`
- Control Groups: `man cgroups`
- Docker Architecture: https://docs.docker.com/get-started/overview/

**Reference:** Docker Field Manual, Chapter 2, Pages 35-68

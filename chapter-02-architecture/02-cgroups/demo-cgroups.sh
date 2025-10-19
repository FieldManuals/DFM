#!/bin/bash

# Chapter 2: Docker Architecture - Cgroups (Control Groups) Demonstration
# This script demonstrates Docker's use of cgroups for resource management

echo "=========================================="
echo "Docker Cgroups Demonstration"
echo "=========================================="

# 1. CPU Limits
echo -e "\n1. CPU LIMITS (--cpus)"
echo "Running CPU-intensive task with different CPU limits..."

echo -e "\nUnlimited CPU:"
docker run --rm alpine sh -c '
    time sh -c "for i in $(seq 1 1000000); do echo $i > /dev/null; done"
' 2>&1 | grep real

echo -e "\nLimited to 0.5 CPU:"
docker run --rm --cpus="0.5" alpine sh -c '
    time sh -c "for i in $(seq 1 1000000); do echo $i > /dev/null; done"
' 2>&1 | grep real

echo "Notice the limited version takes ~2x longer!"

# 2. Memory Limits
echo -e "\n2. MEMORY LIMITS (--memory)"
echo "Testing memory allocation with limits..."

echo -e "\nTrying to allocate 512MB with 256MB limit:"
docker run --rm --memory="256m" alpine sh -c '
    echo "Attempting to allocate 512MB..."
    dd if=/dev/zero of=/tmp/test bs=1M count=512 2>&1 || echo "Killed by OOM!"
'

echo -e "\nWith 1GB limit (succeeds):"
docker run --rm --memory="1g" alpine sh -c '
    echo "Allocating 512MB with 1GB limit..."
    dd if=/dev/zero of=/tmp/test bs=1M count=512 2>&1 && echo "Success!"
    ls -lh /tmp/test
'

# 3. CPU Shares (relative weight)
echo -e "\n3. CPU SHARES (--cpu-shares)"
echo "Running two containers with different CPU priorities..."

# Start low priority container
docker run -d --name low-priority --cpu-shares=256 alpine \
    sh -c 'while true; do echo "low" > /dev/null; done'

# Start high priority container
docker run -d --name high-priority --cpu-shares=1024 alpine \
    sh -c 'while true; do echo "high" > /dev/null; done'

sleep 5

echo "CPU usage (high-priority gets more CPU):"
docker stats --no-stream low-priority high-priority

docker rm -f low-priority high-priority

# 4. Block I/O Limits
echo -e "\n4. BLOCK I/O LIMITS (--device-write-bps)"
echo "Testing disk write speed limits..."

echo -e "\nUnlimited write speed:"
docker run --rm alpine sh -c '
    time dd if=/dev/zero of=/tmp/test bs=1M count=100 2>&1
' | grep -E "(copied|MB/s)"

echo -e "\nLimited to 10MB/s:"
docker run --rm --device-write-bps /dev/sda:10mb alpine sh -c '
    time dd if=/dev/zero of=/tmp/test bs=1M count=100 2>&1
' | grep -E "(copied|MB/s)" || echo "Note: Requires block device access"

# 5. PIDs Limit
echo -e "\n5. PIDS LIMIT (--pids-limit)"
echo "Limiting maximum number of processes..."

echo -e "\nTrying to spawn 100 processes with limit of 10:"
docker run --rm --pids-limit=10 alpine sh -c '
    for i in $(seq 1 100); do
        sleep 60 &
    done
    wait
' 2>&1 | head -n 5

# 6. Real-world example: Resource-constrained application
echo -e "\n6. REAL-WORLD EXAMPLE"
echo "Running nginx with production limits..."

docker run -d \
    --name nginx-limited \
    --cpus="1.0" \
    --memory="512m" \
    --memory-reservation="256m" \
    --pids-limit=100 \
    nginx:alpine

echo "Resource limits applied:"
docker inspect nginx-limited | grep -A 10 "HostConfig"

echo -e "\nContainer stats:"
docker stats --no-stream nginx-limited

docker rm -f nginx-limited

# 7. Inspecting cgroups on host
echo -e "\n7. INSPECTING CGROUPS ON HOST"
echo "Cgroup filesystem location..."

# Find a running container
CID=$(docker run -d alpine sleep 60)

echo "Container ID: $CID"
echo ""
echo "Cgroup paths for this container:"
echo "  CPU: /sys/fs/cgroup/cpu/docker/$CID/"
echo "  Memory: /sys/fs/cgroup/memory/docker/$CID/"
echo "  Block I/O: /sys/fs/cgroup/blkio/docker/$CID/"

if [ -d "/sys/fs/cgroup/cpu/docker" ]; then
    echo -e "\nCPU cgroup settings:"
    ls -la /sys/fs/cgroup/cpu/docker/ 2>/dev/null | head -n 10
fi

docker rm -f $CID

echo -e "\n=========================================="
echo "Cgroups Demonstration Complete"
echo "=========================================="
echo ""
echo "Key Cgroup Controllers:"
echo "  ✓ cpu - CPU time allocation"
echo "  ✓ cpuset - CPU core pinning"
echo "  ✓ memory - RAM limits and reservations"
echo "  ✓ blkio - Block device I/O throttling"
echo "  ✓ pids - Process count limits"
echo "  ✓ net_cls - Network traffic classification"
echo ""
echo "Production Best Practices:"
echo "  • Always set memory limits to prevent OOM"
echo "  • Use CPU limits to ensure fair scheduling"
echo "  • Set PID limits to prevent fork bombs"
echo "  • Use reservations for guaranteed resources"

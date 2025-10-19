#!/bin/bash

# Chapter 2: Docker Architecture - Namespace Demonstration
# This script demonstrates Docker's use of Linux namespaces for isolation

echo "=========================================="
echo "Docker Namespace Demonstration"
echo "=========================================="

# 1. PID Namespace Isolation
echo -e "\n1. PID NAMESPACE ISOLATION"
echo "Starting container with isolated PID namespace..."

docker run --rm --name pid-demo alpine sh -c '
    echo "Inside container:"
    echo "  Process list (ps aux):"
    ps aux
    echo ""
    echo "  PID 1 is the container process, not host init!"
    echo "  Only container processes are visible"
'

echo -e "\nOn host (different view):"
echo "  Container processes have different PIDs on host"
ps aux | grep alpine | head -n 3

# 2. Network Namespace Isolation
echo -e "\n2. NETWORK NAMESPACE ISOLATION"
echo "Starting container with isolated network..."

docker run --rm --name net-demo alpine sh -c '
    echo "Inside container network namespace:"
    ip addr show
    echo ""
    echo "Container has its own network interfaces:"
    echo "  - lo (loopback)"
    echo "  - eth0 (virtual ethernet)"
'

echo -e "\nCompare with host network:"
docker run --rm --network host alpine sh -c '
    echo "With --network host (no isolation):"
    ip addr show | grep -E "^[0-9]" | head -n 5
    echo "  Uses host network interfaces directly!"
'

# 3. Mount Namespace Isolation
echo -e "\n3. MOUNT NAMESPACE ISOLATION"
echo "Container sees isolated filesystem..."

docker run --rm alpine sh -c '
    echo "Inside container:"
    df -h
    echo ""
    echo "Container only sees its own filesystem"
    echo "Host filesystems are not visible (unless mounted)"
'

# 4. UTS Namespace (hostname isolation)
echo -e "\n4. UTS NAMESPACE (Hostname Isolation)"

docker run --rm --hostname my-container alpine sh -c '
    echo "Container hostname: $(hostname)"
    echo "Isolated from host hostname"
'

echo -e "\nHost hostname: $(hostname)"

# 5. IPC Namespace Isolation
echo -e "\n5. IPC NAMESPACE ISOLATION"
echo "Shared memory is isolated between containers..."

# Create first container
docker run -d --name ipc-demo1 alpine sleep 60

# Try to share IPC with second container
docker run --rm --ipc container:ipc-demo1 alpine sh -c '
    echo "This container shares IPC namespace with ipc-demo1"
    echo "They can communicate via shared memory"
'

docker rm -f ipc-demo1

# 6. User Namespace (optional, requires setup)
echo -e "\n6. USER NAMESPACE"
echo "Maps container root to unprivileged user on host"
echo "(Requires userns-remap in daemon.json)"

docker run --rm alpine sh -c '
    echo "Inside container - I am root:"
    id
    echo ""
    echo "But on host, I am mapped to unprivileged user!"
'

echo -e "\n=========================================="
echo "Namespace Demonstration Complete"
echo "=========================================="
echo ""
echo "Key Points:"
echo "  ✓ PID namespace - Isolated process tree"
echo "  ✓ Network namespace - Isolated network stack"
echo "  ✓ Mount namespace - Isolated filesystem"
echo "  ✓ UTS namespace - Isolated hostname"
echo "  ✓ IPC namespace - Isolated inter-process communication"
echo "  ✓ User namespace - UID/GID remapping"
echo ""
echo "This isolation is what makes containers secure and portable!"

#!/bin/bash

# Demo script for Docker Secrets Management

echo "=========================================="
echo "Docker Secrets Management Demo"
echo "=========================================="

# 1. Create secret files
echo -e "\n1. Creating secret files..."
mkdir -p secrets
echo "SuperSecretPassword123!" > secrets/db_password.txt
echo "api-key-abc123xyz789" > secrets/api_key.txt
chmod 600 secrets/*

echo "✓ Secrets created in ./secrets/"

# 2. Start services with secrets
echo -e "\n2. Starting services with secrets..."
docker-compose up -d

sleep 5

# 3. Verify secrets are mounted
echo -e "\n3. Checking secret mounts..."
docker-compose exec app ls -la /run/secrets/

echo -e "\n4. Reading secret from container..."
docker-compose exec app cat /run/secrets/db_password

echo -e "\n5. Checking secret permissions..."
docker-compose exec app stat /run/secrets/db_password

# 6. Demonstrate secrets NOT in environment
echo -e "\n6. Secrets are NOT in environment variables..."
echo "Environment variables (no passwords):"
docker-compose exec app env | grep -i password || echo "✓ No passwords in env!"

# 7. Compare with INSECURE method
echo -e "\n7. INSECURE: Passwords in environment (DON'T DO THIS)"
docker run --rm -e PASSWORD=SuperSecret123 alpine env | grep PASSWORD
echo "⚠️  Anyone with docker inspect access can see this!"

# 8. Demonstrate Docker Swarm secrets (if available)
if docker swarm ca 2>/dev/null; then
    echo -e "\n8. Docker Swarm secrets (encrypted)..."
    echo "SuperSecretPassword123!" | docker secret create db_password -
    docker secret ls
    echo "✓ Secrets encrypted in Swarm"
else
    echo -e "\n8. Docker Swarm not initialized (secrets would be encrypted in Swarm mode)"
fi

echo -e "\n=========================================="
echo "Secrets Management Demo Complete"
echo "=========================================="
echo ""
echo "Key Points:"
echo "  ✓ Secrets mounted at /run/secrets/"
echo "  ✓ Never stored in environment variables"
echo "  ✓ Never in docker inspect output"
echo "  ✓ Encrypted at rest in Swarm mode"
echo "  ✓ Mounted as tmpfs (memory only)"
echo ""
echo "Clean up: docker-compose down && rm -rf secrets/"

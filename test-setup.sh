#!/bin/bash
# Quick test script to verify git-server setup
# This script tests basic functionality of the git server

set -e

CONTAINER_NAME="${CONTAINER_NAME:-git-server-test}"
SSH_PORT="${SSH_PORT:-2222}"
TEST_KEY="test_key"
TEST_REPO="test-repo"

echo "==================================="
echo "Git Server Setup Test"
echo "==================================="
echo ""

# Cleanup function
cleanup() {
    echo ""
    echo "Cleaning up..."
    rm -rf "$TEST_REPO" "$TEST_KEY" "$TEST_KEY.pub" authorized_keys 2>/dev/null || true
    docker stop "$CONTAINER_NAME" 2>/dev/null || true
    docker rm "$CONTAINER_NAME" 2>/dev/null || true
    echo "Cleanup complete"
}

# Set trap to cleanup on exit
trap cleanup EXIT

# Step 1: Generate test SSH key
echo "Step 1: Generating test SSH key..."
ssh-keygen -t ed25519 -f "$TEST_KEY" -N "" -C "test@git-server" >/dev/null 2>&1
cp "$TEST_KEY.pub" authorized_keys
echo "✓ SSH key generated"
echo ""

# Step 2: Build the image
echo "Step 2: Building Docker image..."
if docker build -t git-server:test . >/dev/null 2>&1; then
    echo "✓ Image built successfully"
else
    echo "✗ Failed to build image"
    exit 1
fi
echo ""

# Step 3: Start container
echo "Step 3: Starting container..."
docker run -d \
    --name "$CONTAINER_NAME" \
    -p "$SSH_PORT:22" \
    -v "$(pwd)/authorized_keys:/home/git/.ssh/authorized_keys:ro" \
    git-server:test >/dev/null 2>&1

# Wait for SSH to be ready
echo "Waiting for SSH daemon to start..."
sleep 3

if docker ps | grep -q "$CONTAINER_NAME"; then
    echo "✓ Container started"
else
    echo "✗ Container failed to start"
    docker logs "$CONTAINER_NAME"
    exit 1
fi
echo ""

# Step 4: Test SSH connection
echo "Step 4: Testing SSH connection..."
if ssh -i "$TEST_KEY" -p "$SSH_PORT" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null git@localhost 2>&1 | grep -q "Interactive git shell"; then
    echo "✓ SSH connection successful"
else
    echo "✗ SSH connection failed"
    exit 1
fi
echo ""

# Step 5: Test git-shell restrictions
echo "Step 5: Testing git-shell restrictions..."
if ssh -i "$TEST_KEY" -p "$SSH_PORT" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null git@localhost "whoami" 2>&1 | grep -q "not enabled"; then
    echo "✓ git-shell properly restricts commands"
else
    echo "✗ git-shell restrictions not working"
    exit 1
fi
echo ""

# Step 6: Create test repository
echo "Step 6: Creating test repository..."
docker exec "$CONTAINER_NAME" /usr/local/bin/init-repo.sh "$TEST_REPO" >/dev/null 2>&1
if docker exec "$CONTAINER_NAME" test -d "/srv/git/$TEST_REPO.git"; then
    echo "✓ Repository created"
else
    echo "✗ Repository creation failed"
    exit 1
fi
echo ""

# Step 7: Clone repository
echo "Step 7: Testing git clone..."
export GIT_SSH_COMMAND="ssh -i $(pwd)/$TEST_KEY -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
if git clone -q "ssh://git@localhost:$SSH_PORT/srv/git/$TEST_REPO.git" 2>/dev/null; then
    echo "✓ Repository cloned"
else
    echo "✗ Clone failed"
    exit 1
fi
echo ""

# Step 8: Push changes
echo "Step 8: Testing git push..."
cd "$TEST_REPO"
echo "# Test Repository" > README.md
git add README.md
git commit -q -m "Initial commit"
if git push -q origin main 2>/dev/null || git push -q origin master 2>/dev/null; then
    echo "✓ Push successful"
else
    echo "✗ Push failed"
    exit 1
fi
cd ..
echo ""

# Step 9: Verify data persisted
echo "Step 9: Verifying repository contents..."
if docker exec "$CONTAINER_NAME" test -f "/srv/git/$TEST_REPO.git/refs/heads/main" || \
   docker exec "$CONTAINER_NAME" test -f "/srv/git/$TEST_REPO.git/refs/heads/master"; then
    echo "✓ Repository data persisted"
else
    echo "✗ Repository data not found"
    exit 1
fi
echo ""

# Step 10: Test git hooks
echo "Step 10: Testing git hooks..."
docker exec "$CONTAINER_NAME" bash -c "cat > /srv/git/$TEST_REPO.git/hooks/post-receive << 'EOF'
#!/bin/bash
echo \"HOOK_EXECUTED: Push received at \$(date)\"
EOF"
docker exec "$CONTAINER_NAME" chmod +x "/srv/git/$TEST_REPO.git/hooks/post-receive"

cd "$TEST_REPO"
echo "update" >> README.md
git add README.md
git commit -q -m "Test hook"
if git push origin main 2>&1 | grep -q "HOOK_EXECUTED" || git push origin master 2>&1 | grep -q "HOOK_EXECUTED"; then
    echo "✓ Git hooks working"
else
    echo "✗ Git hooks not executed"
    exit 1
fi
cd ..
echo ""

# All tests passed
echo "==================================="
echo "✓ All tests passed!"
echo "==================================="
echo ""
echo "Your git-server is working correctly!"
echo ""
echo "To use it:"
echo "  1. Create your authorized_keys file with your SSH public keys"
echo "  2. Start the server: docker-compose up -d"
echo "  3. Create repositories: docker exec git-server /usr/local/bin/init-repo.sh <name>"
echo "  4. Clone: git clone ssh://git@localhost:2222/srv/git/<name>.git"
echo ""

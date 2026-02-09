# Testing Guide

This document describes how to test the git-server Docker image.

## Automated Testing

### Quick Test (Recommended)

Run the automated test script:

```bash
./test-setup.sh
```

This script automatically tests:
- ✅ Docker image builds successfully
- ✅ Container starts and SSH daemon runs
- ✅ SSH public key authentication works
- ✅ git-shell restricts non-git commands
- ✅ Repository creation
- ✅ Git clone operation
- ✅ Git push operation
- ✅ Data persistence
- ✅ Git hooks execution

The script automatically cleans up after itself.

## Manual Testing

### 1. Build Test

```bash
docker build -t git-server:test .
```

**Expected:** Build completes without errors.

### 2. Container Start Test

```bash
# Generate test key
ssh-keygen -t ed25519 -f test_key -N "" -C "test@git-server"
cp test_key.pub authorized_keys

# Start container
docker run -d \
  --name git-server-test \
  -p 2222:22 \
  -v $(pwd)/authorized_keys:/home/git/.ssh/authorized_keys:ro \
  git-server:test

# Check it's running
docker ps | grep git-server-test

# Check logs
docker logs git-server-test
```

**Expected:**
- Container starts successfully
- Logs show "Git Server Ready"
- No error messages in logs

### 3. SSH Connection Test

```bash
# Test connection (should show git-shell message)
ssh -i test_key -p 2222 -o StrictHostKeyChecking=no git@localhost
```

**Expected:**
```
fatal: Interactive git shell is not enabled.
hint: ~/git-shell-commands should exist and have read and execute access.
```

### 4. Security Tests

#### Test password authentication is disabled
```bash
ssh -o PubkeyAuthentication=no -p 2222 git@localhost
```
**Expected:** `Permission denied (publickey).`

#### Test root login is disabled
```bash
ssh -i test_key -p 2222 root@localhost
```
**Expected:** Connection refused or permission denied.

#### Test git-shell restrictions
```bash
# Try to execute shell commands (should fail)
ssh -i test_key -p 2222 git@localhost "whoami"
ssh -i test_key -p 2222 git@localhost "ls"
ssh -i test_key -p 2222 git@localhost "cat /etc/passwd"
```
**Expected:** All commands rejected with "Interactive git shell is not enabled" message.

#### Test only git user can connect
```bash
# Try connecting as other users (should fail)
ssh -i test_key -p 2222 admin@localhost
ssh -i test_key -p 2222 ubuntu@localhost
```
**Expected:** Permission denied or connection refused.

### 5. Repository Operations Test

#### Create repository
```bash
docker exec git-server-test /usr/local/bin/init-repo.sh test-repo
```
**Expected:** Success message, repository created at `/srv/git/test-repo.git`

#### Verify repository structure
```bash
docker exec git-server-test ls -la /srv/git/test-repo.git
```
**Expected:** Bare git repository structure (HEAD, objects/, refs/, etc.)

#### Test repository ownership
```bash
docker exec git-server-test stat -c '%U:%G' /srv/git/test-repo.git
```
**Expected:** `git:git`

### 6. Git Operations Test

#### Clone repository
```bash
export GIT_SSH_COMMAND="ssh -i $(pwd)/test_key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
git clone ssh://git@localhost:2222/srv/git/test-repo.git
```
**Expected:** Clone succeeds, creates `test-repo` directory.

#### Make changes and push
```bash
cd test-repo
git config user.email "test@example.com"
git config user.name "Test User"

echo "# Test" > README.md
git add README.md
git commit -m "Initial commit"
git push origin main
```
**Expected:** Push succeeds, no errors.

#### Clone again to verify
```bash
cd ..
rm -rf test-repo
git clone ssh://git@localhost:2222/srv/git/test-repo.git test-repo-2
cd test-repo-2
cat README.md
```
**Expected:** README.md contains "# Test"

### 7. Git Hooks Test

#### Create post-receive hook
```bash
docker exec git-server-test bash -c 'cat > /srv/git/test-repo.git/hooks/post-receive << "EOF"
#!/bin/bash
echo "HOOK_OUTPUT: Push received at $(date)"
while read oldrev newrev refname; do
    echo "HOOK_OUTPUT: Updated $refname from $oldrev to $newrev"
done
EOF'

docker exec git-server-test chmod +x /srv/git/test-repo.git/hooks/post-receive
```

#### Test hook executes
```bash
cd test-repo
echo "update" >> README.md
git add README.md
git commit -m "Test hook"
git push origin main
```
**Expected:** Push output includes "HOOK_OUTPUT" messages.

#### Test pre-receive hook (rejection)
```bash
docker exec git-server-test bash -c 'cat > /srv/git/test-repo.git/hooks/pre-receive << "EOF"
#!/bin/bash
echo "ERROR: Pre-receive hook rejecting push"
exit 1
EOF'

docker exec git-server-test chmod +x /srv/git/test-repo.git/hooks/pre-receive

# Try to push (should fail)
echo "another update" >> README.md
git add README.md
git commit -m "Should be rejected"
git push origin main
```
**Expected:** Push rejected with error message from hook.

### 8. Volume Persistence Test

#### Stop and restart container
```bash
docker stop git-server-test
docker start git-server-test

# Wait for SSH to start
sleep 3

# Verify repository still exists
docker exec git-server-test ls /srv/git/test-repo.git
```
**Expected:** Repository still exists after restart.

### 9. Environment Variables Test

#### Test GIT_USER_UID/GID
```bash
docker run -d \
  --name git-server-uid-test \
  -p 2223:22 \
  -e GIT_USER_UID=1500 \
  -e GIT_USER_GID=1500 \
  -v $(pwd)/authorized_keys:/home/git/.ssh/authorized_keys:ro \
  git-server:test

# Check UID/GID
docker exec git-server-uid-test id git
```
**Expected:** Output shows `uid=1500(git) gid=1500(git)`

```bash
docker stop git-server-uid-test
docker rm git-server-uid-test
```

#### Test SSH_AUTHORIZED_KEYS_URL
```bash
docker run -d \
  --name git-server-url-test \
  -p 2223:22 \
  -e SSH_AUTHORIZED_KEYS_URL=https://github.com/torvalds.keys \
  git-server:test

# Wait for startup
sleep 3

# Check keys were fetched
docker exec git-server-url-test wc -l /home/git/.ssh/authorized_keys
```
**Expected:** authorized_keys contains keys from URL.

```bash
docker stop git-server-url-test
docker rm git-server-url-test
```

#### Test REPOSITORIES_HOME_LINK
```bash
docker run -d \
  --name git-server-link-test \
  -p 2223:22 \
  -e REPOSITORIES_HOME_LINK=true \
  -v $(pwd)/authorized_keys:/home/git/.ssh/authorized_keys:ro \
  git-server:test

# Check symlink exists
docker exec git-server-link-test ls -la /home/git/repos
```
**Expected:** Symlink `/home/git/repos -> /srv/git` exists.

```bash
docker stop git-server-link-test
docker rm git-server-link-test
```

### 10. Docker Compose Test

```bash
# Start with compose
docker-compose up -d

# Check service is running
docker-compose ps

# Check logs
docker-compose logs git-server

# Create repository
docker-compose exec git-server /usr/local/bin/init-repo.sh compose-test

# Test clone
export GIT_SSH_COMMAND="ssh -i $(pwd)/test_key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
git clone ssh://git@localhost:2222/srv/git/compose-test.git

# Stop
docker-compose down
```

**Expected:** All operations succeed.

### 11. Multi-User Test

```bash
# Create multiple SSH keys
ssh-keygen -t ed25519 -f user1_key -N "" -C "user1@git-server"
ssh-keygen -t ed25519 -f user2_key -N "" -C "user2@git-server"

# Combine keys
cat user1_key.pub user2_key.pub > authorized_keys

# Restart container
docker restart git-server-test
sleep 3

# Test both users can connect
ssh -i user1_key -p 2222 -o StrictHostKeyChecking=no git@localhost
ssh -i user2_key -p 2222 -o StrictHostKeyChecking=no git@localhost
```

**Expected:** Both users can connect successfully.

### 12. Performance Test

```bash
# Create multiple repositories
for i in {1..10}; do
    docker exec git-server-test /usr/local/bin/init-repo.sh "repo-$i"
done

# Clone all repositories
for i in {1..10}; do
    git clone ssh://git@localhost:2222/srv/git/repo-$i.git
done

# Time a large push
cd repo-1
dd if=/dev/zero of=largefile bs=1M count=10
git add largefile
git commit -m "Large file"
time git push origin main
```

**Expected:** All operations complete without errors.

## Cleanup

```bash
# Stop and remove container
docker stop git-server-test
docker rm git-server-test

# Remove test files
rm -rf test_key test_key.pub authorized_keys test-repo* user1_key* user2_key* repo-*

# Remove test volumes
docker volume rm $(docker volume ls -q | grep git) 2>/dev/null || true

# Remove test images
docker rmi git-server:test
```

## Integration Testing

### Test with CI/CD

Example GitHub Actions workflow:

```yaml
name: Test Git Server
on: [push]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run tests
        run: ./test-setup.sh
```

### Test with Multiple Clients

Test concurrent operations:

```bash
# Terminal 1
git clone ssh://git@localhost:2222/srv/git/test-repo.git test-1
cd test-1
echo "from client 1" > file1.txt
git add file1.txt
git commit -m "From client 1"
git push origin main

# Terminal 2 (simultaneously)
git clone ssh://git@localhost:2222/srv/git/test-repo.git test-2
cd test-2
echo "from client 2" > file2.txt
git add file2.txt
git commit -m "From client 2"
git push origin main
```

**Expected:** Both pushes succeed (may need merge/pull).

## Troubleshooting Tests

If tests fail, check:

1. **Docker is running:** `docker info`
2. **Ports are available:** `lsof -i :2222`
3. **Permissions are correct:** Check file permissions in container
4. **Logs for errors:** `docker logs git-server-test`
5. **SSH verbose mode:** `ssh -vvv -i test_key -p 2222 git@localhost`

## Test Coverage Checklist

- [ ] Build process
- [ ] Container startup
- [ ] SSH authentication (key-based)
- [ ] SSH authentication (password blocked)
- [ ] Root login blocked
- [ ] git-shell restrictions
- [ ] User restrictions (only git user)
- [ ] Repository creation
- [ ] Repository permissions
- [ ] Git clone
- [ ] Git push
- [ ] Git pull
- [ ] Data persistence
- [ ] Git hooks (post-receive)
- [ ] Git hooks (pre-receive)
- [ ] Git hooks (update)
- [ ] Environment variables (UID/GID)
- [ ] Environment variables (keys URL)
- [ ] Environment variables (home link)
- [ ] Volume mounts
- [ ] Docker Compose
- [ ] Multi-user access
- [ ] Concurrent operations
- [ ] Host key persistence
- [ ] Error handling
- [ ] Security configuration

## Continuous Testing

Set up automated testing:

```bash
# Run tests on every build
docker build -t git-server:latest . && ./test-setup.sh

# Run tests in watch mode (requires entr)
ls *.sh Dockerfile sshd_config | entr -r ./test-setup.sh
```

## Reporting Issues

When reporting test failures, include:

1. Test that failed
2. Expected behavior
3. Actual behavior
4. Docker version: `docker --version`
5. OS: `uname -a`
6. Container logs: `docker logs git-server-test`
7. Steps to reproduce

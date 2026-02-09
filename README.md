# Ubuntu SSH+Git Server Docker Image

A secure, production-ready SSH+Git server running on Ubuntu 24.04 LTS. Users authenticate via SSH public keys and interact with git repositories through a restricted git-shell environment.

## Features

- 🔒 **Secure by default**: SSH public key authentication only (no passwords)
- 🐚 **Restricted access**: Users run in git-shell (git commands only, no shell access)
- 📦 **Multiple repositories**: Support for unlimited repositories under single git user
- 🪝 **Git hooks support**: Full support for server-side git hooks
- 🐧 **Ubuntu 24.04 LTS**: Long-term support base image
- 🔑 **Persistent host keys**: Avoids "host key changed" warnings on container restart
- 📊 **Volume support**: Persistent storage for repositories, keys, and host keys

## Quick Start

### 1. Create authorized_keys file

Add your SSH public key(s) to an `authorized_keys` file:

```bash
# Copy your existing public key
cp ~/.ssh/id_rsa.pub authorized_keys

# Or create a new key
ssh-keygen -t ed25519 -f git_key -N "" -C "git@server"
cp git_key.pub authorized_keys
```

### 2. Build the image

```bash
docker build -t git-server:latest .
```

### 3. Run the container

```bash
docker run -d \
  --name git-server \
  -p 2222:22 \
  -v $(pwd)/authorized_keys:/home/git/.ssh/authorized_keys:ro \
  -v git-repos:/srv/git \
  -v ssh-host-keys:/etc/ssh/ssh_host_keys \
  git-server:latest
```

### 4. Create a repository

```bash
docker exec git-server /usr/local/bin/init-repo.sh myproject
```

### 5. Clone and use

```bash
git clone ssh://git@localhost:2222/srv/git/myproject.git
cd myproject
echo "# My Project" > README.md
git add README.md
git commit -m "Initial commit"
git push origin main
```

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `GIT_USER_UID` | Set git user's UID (useful for matching host permissions) | - |
| `GIT_USER_GID` | Set git user's GID | - |
| `SSH_AUTHORIZED_KEYS_URL` | URL to fetch authorized_keys from (e.g., `https://github.com/username.keys`) | - |
| `REPOSITORIES_HOME_LINK` | Create symlink `/home/git/repos` → `/srv/git` for shorter clone URLs | `false` |

### Example with environment variables

```bash
docker run -d \
  --name git-server \
  -p 2222:22 \
  -e GIT_USER_UID=1000 \
  -e GIT_USER_GID=1000 \
  -e SSH_AUTHORIZED_KEYS_URL=https://github.com/yourusername.keys \
  -e REPOSITORIES_HOME_LINK=true \
  -v git-repos:/srv/git \
  -v ssh-host-keys:/etc/ssh/ssh_host_keys \
  git-server:latest
```

## SSH Key Setup

### Option 1: Mount authorized_keys file (Recommended)

```bash
# Create authorized_keys with your public key(s)
cat ~/.ssh/id_rsa.pub > authorized_keys

# Mount it read-only
docker run -d \
  -v $(pwd)/authorized_keys:/home/git/.ssh/authorized_keys:ro \
  ...
```

### Option 2: Fetch from GitHub

```bash
docker run -d \
  -e SSH_AUTHORIZED_KEYS_URL=https://github.com/username.keys \
  ...
```

### Option 3: Copy into running container

```bash
docker cp ~/.ssh/id_rsa.pub git-server:/home/git/.ssh/authorized_keys
docker exec git-server chown git:git /home/git/.ssh/authorized_keys
docker exec git-server chmod 600 /home/git/.ssh/authorized_keys
```

### Option 4: Multiple users/keys

```bash
# Combine multiple GitHub users
curl -fsSL https://github.com/user1.keys > authorized_keys
curl -fsSL https://github.com/user2.keys >> authorized_keys
curl -fsSL https://github.com/user3.keys >> authorized_keys
```

## Repository Management

### Create a new repository

```bash
docker exec git-server /usr/local/bin/init-repo.sh myproject
```

This creates a bare repository at `/srv/git/myproject.git`.

### Clone a repository

Standard format:
```bash
git clone ssh://git@hostname:2222/srv/git/myproject.git
```

If `REPOSITORIES_HOME_LINK=true`:
```bash
git clone ssh://git@hostname:2222/home/git/repos/myproject.git
```

Short format (requires SSH config):
```bash
# In ~/.ssh/config:
Host gitserver
    HostName localhost
    Port 2222
    User git
    IdentityFile ~/.ssh/git_key

# Then clone with:
git clone gitserver:/srv/git/myproject.git
```

### List repositories

```bash
docker exec git-server ls -la /srv/git
```

### Delete a repository

```bash
docker exec git-server rm -rf /srv/git/myproject.git
```

## Git Hooks

Git hooks allow you to run custom scripts on git events (push, commit, etc.).

### Available hooks

Common server-side hooks:
- `pre-receive`: Runs before refs are updated, can reject pushes
- `update`: Runs once per branch being updated
- `post-receive`: Runs after refs are updated, useful for notifications/deployments

### Adding hooks

#### Method 1: Copy into container

```bash
# Create hook script locally
cat > post-receive << 'EOF'
#!/bin/bash
echo "Push received at $(date)"
echo "Pushed by: $USER"
while read oldrev newrev refname; do
    echo "  Updated: $refname"
done
EOF

# Copy to container
docker cp post-receive git-server:/srv/git/myproject.git/hooks/post-receive

# Make executable
docker exec git-server chmod +x /srv/git/myproject.git/hooks/post-receive
docker exec git-server chown git:git /srv/git/myproject.git/hooks/post-receive
```

#### Method 2: Create inside container

```bash
docker exec git-server bash -c 'cat > /srv/git/myproject.git/hooks/post-receive << "EOF"
#!/bin/bash
echo "Push received at $(date)"
EOF'

docker exec git-server chmod +x /srv/git/myproject.git/hooks/post-receive
```

### Example: Deployment hook

```bash
#!/bin/bash
# post-receive hook for automatic deployment

GIT_DIR=/srv/git/myproject.git
DEPLOY_DIR=/var/www/myproject

while read oldrev newrev refname; do
    if [[ $refname == "refs/heads/main" ]]; then
        echo "Deploying main branch..."
        git --work-tree=$DEPLOY_DIR --git-dir=$GIT_DIR checkout -f main
        echo "Deployment complete!"
    fi
done
```

### Example: Notification hook

```bash
#!/bin/bash
# post-receive hook for Slack notifications

SLACK_WEBHOOK="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"

while read oldrev newrev refname; do
    branch=$(git rev-parse --symbolic --abbrev-ref $refname)
    message="Push to $branch: $(git log -1 --pretty=format:'%h - %s' $newrev)"

    curl -X POST -H 'Content-type: application/json' \
        --data "{\"text\":\"$message\"}" \
        $SLACK_WEBHOOK
done
```

## Volume Management

### Volumes

The container uses three volumes:

1. **`/srv/git`**: Git repositories (required)
2. **`/home/git/.ssh`**: SSH authorized_keys (required)
3. **`/etc/ssh/ssh_host_keys`**: SSH host keys (recommended)

### Backup repositories

```bash
# Using docker cp
docker cp git-server:/srv/git ./backup

# Using volume backup container
docker run --rm \
  -v git-repos:/data \
  -v $(pwd):/backup \
  ubuntu tar czf /backup/git-repos-$(date +%Y%m%d).tar.gz /data
```

### Restore repositories

```bash
# Using docker cp
docker cp ./backup/myproject.git git-server:/srv/git/

# Fix permissions
docker exec git-server chown -R git:git /srv/git
```

### Inspect volume location

```bash
docker volume inspect git-repos
```

## Security Considerations

### What's secured

✅ **Public key authentication only** - No password authentication
✅ **git-shell restriction** - Users cannot execute arbitrary commands
✅ **Root login disabled** - Root account cannot connect via SSH
✅ **Limited user access** - Only git user can connect
✅ **No port forwarding** - X11, TCP, and agent forwarding disabled
✅ **Minimal packages** - Only essential packages installed
✅ **Proper permissions** - Restricted file permissions (700/.ssh, 600/authorized_keys)
✅ **Non-root operations** - Git operations run as non-root user
✅ **Persistent host keys** - Prevents MITM attacks

### Best practices

1. **Use unique SSH keys** - Don't reuse keys across services
2. **Mount authorized_keys read-only** - Prevents modification
3. **Keep base image updated** - Rebuild regularly for security patches
4. **Use resource limits** - Limit CPU and memory usage
5. **Monitor logs** - Watch for suspicious SSH activity
6. **Rotate keys regularly** - Update SSH keys periodically
7. **Use strong keys** - Prefer Ed25519 or RSA 4096-bit keys
8. **Restrict network access** - Use firewall rules to limit access

### Testing security

```bash
# Verify password auth is disabled
ssh -o PubkeyAuthentication=no -p 2222 git@localhost
# Should fail: "Permission denied (publickey)"

# Verify root login is disabled
ssh -p 2222 root@localhost
# Should fail

# Verify shell commands are blocked
ssh -p 2222 git@localhost whoami
# Should show: "fatal: Interactive git shell is not enabled"

# Verify git-shell restrictions
ssh -p 2222 git@localhost "cat /etc/passwd"
# Should be rejected
```

## Troubleshooting

### Cannot connect via SSH

**Problem**: `Permission denied (publickey)`

**Solutions**:
1. Check authorized_keys is mounted and contains your public key
2. Verify key permissions: `ls -la /home/git/.ssh/authorized_keys` (should be 600)
3. Check SSH key is loaded: `ssh-add -l`
4. Try verbose mode: `ssh -vvv -p 2222 git@localhost`
5. Check container logs: `docker logs git-server`

### "Host key verification failed"

**Problem**: SSH complains about changed host key

**Solutions**:
1. Use persistent volume for host keys (recommended)
2. Remove old key: `ssh-keygen -R "[localhost]:2222"`
3. Accept new key: `ssh-keyscan -p 2222 localhost >> ~/.ssh/known_hosts`

### Permission denied when pushing

**Problem**: Cannot push to repository

**Solutions**:
1. Check repository ownership: `docker exec git-server ls -la /srv/git`
2. Fix ownership: `docker exec git-server chown -R git:git /srv/git`
3. Check repository path is correct in clone URL
4. Verify repository exists: `docker exec git-server ls /srv/git`

### Git hooks not executing

**Problem**: Hooks don't run on push

**Solutions**:
1. Ensure hook is executable: `chmod +x post-receive`
2. Check hook location: `/srv/git/myproject.git/hooks/post-receive`
3. Verify ownership: `chown git:git post-receive`
4. Test hook manually: `docker exec git-server /srv/git/myproject.git/hooks/post-receive`
5. Check hook output in push messages

### Volume permission issues

**Problem**: Cannot access files in mounted volumes

**Solutions**:
1. Set GIT_USER_UID/GID to match host user:
   ```bash
   docker run -e GIT_USER_UID=$(id -u) -e GIT_USER_GID=$(id -g) ...
   ```
2. Check volume ownership: `docker exec git-server ls -la /srv/git`
3. Fix permissions: `docker exec git-server chown -R git:git /srv/git`

### Container won't start

**Problem**: Container exits immediately

**Solutions**:
1. Check logs: `docker logs git-server`
2. Verify sshd_config syntax: `docker exec git-server sshd -t`
3. Check authorized_keys exists: `docker exec git-server ls -la /home/git/.ssh`
4. Run interactively: `docker run -it --rm --entrypoint /bin/bash git-server`

## Advanced Usage

### Using with CI/CD

```yaml
# .github/workflows/deploy.yml
name: Deploy
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup SSH
        run: |
          mkdir -p ~/.ssh
          echo "${{ secrets.GIT_SERVER_KEY }}" > ~/.ssh/id_rsa
          chmod 600 ~/.ssh/id_rsa
          ssh-keyscan -p 2222 git-server.example.com >> ~/.ssh/known_hosts
      - name: Push to git server
        run: |
          git remote add production ssh://git@git-server.example.com:2222/srv/git/myproject.git
          git push production main
```

### Multiple containers

Run multiple instances for different environments:

```bash
# Development server
docker run -d \
  --name git-server-dev \
  -p 2222:22 \
  -v git-repos-dev:/srv/git \
  -v ssh-host-keys-dev:/etc/ssh/ssh_host_keys \
  -v $(pwd)/authorized_keys:/home/git/.ssh/authorized_keys:ro \
  git-server:latest

# Production server
docker run -d \
  --name git-server-prod \
  -p 2223:22 \
  -v git-repos-prod:/srv/git \
  -v ssh-host-keys-prod:/etc/ssh/ssh_host_keys \
  -v $(pwd)/authorized_keys:/home/git/.ssh/authorized_keys:ro \
  git-server:latest
```

### Health monitoring

```bash
# Check SSH is responding
docker exec git-server pgrep sshd

# Check repository count
docker exec git-server sh -c 'ls -1 /srv/git | wc -l'

# Monitor connections
docker exec git-server sh -c 'ss -tnp | grep sshd'
```

## Contributing

Contributions welcome! Please open an issue or pull request.

## License

MIT License - see LICENSE file for details.

## Related Projects

- [rockstorm101/git-server-docker](https://github.com/rockstorm101/git-server-docker) - Alpine-based git server
- [jkarlosb/git-server-docker](https://github.com/jkarlosb/git-server-docker) - Another git server implementation

## References

- [Git on the Server - Git Book](https://git-scm.com/book/en/v2/Git-on-the-Server-Setting-Up-the-Server)
- [git-shell Documentation](https://git-scm.com/docs/git-shell)
- [OpenSSH Server Documentation](https://www.openssh.com/manual.html)

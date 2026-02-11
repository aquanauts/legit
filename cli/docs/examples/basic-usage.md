# Basic Usage Examples

Common workflows and examples for using legit.

## First Time Setup

### Complete workflow from installation to first push

```bash
# Install legit
curl -fsSL https://raw.githubusercontent.com/USERNAME/legit/main/cli/install.sh | bash

# Start the server (will auto-detect SSH keys)
legit start

# Create a repository
legit create-repo myproject

# Clone it
git clone ssh://git@localhost:2222/home/git/repos/myproject.git
cd myproject

# Add content
echo "# My Project" > README.md
echo "A simple project" >> README.md
git add README.md
git commit -m "Initial commit"

# Push
git push origin main

# Success! 🎉
```

## Daily Development

### Creating and using multiple repositories

```bash
# Create repositories for different projects
legit create-repo website
legit create-repo api
legit create-repo mobile-app

# List all repositories
legit list-repos

# Clone the ones you need
git clone ssh://git@localhost:2222/home/git/repos/website.git
git clone ssh://git@localhost:2222/home/git/repos/api.git
```

### Working with existing repositories

```bash
# Clone
git clone ssh://git@localhost:2222/home/git/repos/website.git
cd website

# Make changes
vim index.html
git add index.html
git commit -m "Update homepage"

# Push
git push

# Pull changes from team members
git pull
```

## Team Collaboration

### Adding team members

```bash
# Get their SSH public keys and add to authorized_keys
curl https://github.com/alice.keys >> ~/.config/legit/authorized_keys
curl https://github.com/bob.keys >> ~/.config/legit/authorized_keys

# Restart server to apply changes
legit restart

# Team members can now clone
# (on their machines)
git clone ssh://git@yourserver.com:2222/home/git/repos/project.git
```

### Setting up shared access

```bash
# On the server
legit create-repo team-project

# Share clone URL with team
echo "Clone with: git clone ssh://git@yourserver.com:2222/home/git/repos/team-project.git"

# Each team member adds SSH config
# ~/.ssh/config
Host teamgit
    HostName yourserver.com
    Port 2222
    User git
    IdentityFile ~/.ssh/id_rsa

# Then they can use
git clone teamgit:/home/git/repos/team-project.git
```

## Server Management

### Starting and stopping

```bash
# Start server
legit start

# Check if running
legit status

# View logs
legit logs

# Stop server
legit stop

# Restart (useful after config changes)
legit restart
```

### Monitoring

```bash
# Follow logs in real-time
legit logs -f

# Check status
legit status

# List all repositories
legit list-repos

# Open shell for inspection
legit shell
ls -la /home/git/repos
exit
```

## Configuration

### Custom SSH port

```bash
# Create config file
cat > ~/.config/legit/config << 'EOF'
SSH_PORT=2223
EOF

# Restart to apply
legit restart

# Now use port 2223
git clone ssh://git@localhost:2223/home/git/repos/myproject.git
```

### Using specific image version

```bash
# Create config file
cat > ~/.config/legit/config << 'EOF'
IMAGE=ghcr.io/username/legit-server:v1.0.0
EOF

# Pull and start
legit pull v1.0.0
legit restart
```

### Matching user permissions

```bash
# Useful for bind-mounted volumes
cat > ~/.config/legit/config << 'EOF'
GIT_USER_UID=$(id -u)
GIT_USER_GID=$(id -g)
EOF

# Restart to apply
legit restart
```

## SSH Configuration

### Local development

```bash
# Add to ~/.ssh/config
cat >> ~/.ssh/config << 'EOF'

Host localgit
    HostName localhost
    Port 2222
    User git
    IdentityFile ~/.ssh/id_rsa

EOF

# Now use shorter commands
git clone localgit:/home/git/repos/myproject.git
git push localgit
git pull localgit
```

### Remote server

```bash
# Add to ~/.ssh/config
cat >> ~/.ssh/config << 'EOF'

Host mygitserver
    HostName server.example.com
    Port 2222
    User git
    IdentityFile ~/.ssh/id_rsa

EOF

# Use anywhere
git clone mygitserver:/home/git/repos/myproject.git
```

### Multiple servers

```bash
# Add to ~/.ssh/config
cat >> ~/.ssh/config << 'EOF'

Host devgit
    HostName dev.example.com
    Port 2222
    User git

Host prodgit
    HostName prod.example.com
    Port 2222
    User git

EOF

# Use specific servers
git clone devgit:/home/git/repos/myproject.git
git clone prodgit:/home/git/repos/myproject.git
```

## Maintenance

### Updating legit

```bash
# Update CLI script
curl -fsSL https://raw.githubusercontent.com/USERNAME/legit/main/cli/install.sh | bash

# Update Docker image
legit pull latest

# Restart with new image
legit restart

# Verify versions
legit version
```

### Backing up repositories

```bash
# Stop server
legit stop

# Backup all repositories
docker run --rm \
  -v git-repos:/data \
  -v $(pwd):/backup \
  ubuntu tar czf /backup/git-backup-$(date +%Y%m%d).tar.gz /data

# Restart server
legit start
```

### Restoring repositories

```bash
# Stop server
legit stop

# Restore backup
docker run --rm \
  -v git-repos:/data \
  -v $(pwd):/backup \
  ubuntu tar xzf /backup/git-backup-20260209.tar.gz -C /

# Restart server
legit start

# Verify
legit list-repos
```

### Cleaning up

```bash
# Stop and remove container
legit stop

# Remove volumes (WARNING: deletes all repositories!)
docker volume rm git-repos ssh-host-keys

# Remove CLI
sudo rm /usr/local/bin/legit

# Remove config
rm -rf ~/.config/legit
```

## Troubleshooting

### Can't connect via SSH

```bash
# Check server status
legit status

# View logs for errors
legit logs

# Test SSH connection with verbose output
ssh -vvv -p 2222 git@localhost

# Check authorized_keys
cat ~/.config/legit/authorized_keys
```

### Permission issues

```bash
# Open shell and check permissions
legit shell

# Inside container
ls -la /home/git/repos
ls -la /home/git/.ssh

# Exit shell
exit

# If needed, set matching UID/GID
echo "GIT_USER_UID=$(id -u)" >> ~/.config/legit/config
echo "GIT_USER_GID=$(id -g)" >> ~/.config/legit/config
legit restart
```

### Repository not found

```bash
# List repositories
legit list-repos

# Check if repository exists
legit shell
ls /home/git/repos
exit

# Create if missing
legit create-repo myproject
```

### Host key changed warning

```bash
# This happens if container was recreated without persistent host keys
# Solution: Remove old key
ssh-keygen -R "[localhost]:2222"

# Or use persistent host keys (already enabled by default)
```

## Advanced Usage

### Running multiple instances

```bash
# Instance 1: Development
export LEGIT_CONTAINER=legit-dev
export LEGIT_SSH_PORT=2222
legit start

# Instance 2: Testing
export LEGIT_CONTAINER=legit-test
export LEGIT_SSH_PORT=2223
legit start

# Instance 3: Production
export LEGIT_CONTAINER=legit-prod
export LEGIT_SSH_PORT=2224
legit start

# List all running
docker ps | grep legit
```

### Using with CI/CD

```yaml
# GitHub Actions example
- name: Deploy to Git Server
  run: |
    # Setup SSH
    mkdir -p ~/.ssh
    echo "${{ secrets.GIT_SERVER_KEY }}" > ~/.ssh/id_rsa
    chmod 600 ~/.ssh/id_rsa
    ssh-keyscan -p 2222 git-server.example.com >> ~/.ssh/known_hosts

    # Push to server
    git remote add production ssh://git@git-server.example.com:2222/home/git/repos/myapp.git
    git push production main
```

### Repository mirroring

```bash
# Clone from GitHub
git clone https://github.com/username/project.git
cd project

# Add legit server as remote
git remote add backup ssh://git@localhost:2222/home/git/repos/project.git

# Push to backup
git push backup --all
git push backup --tags

# Now all branches and tags are mirrored
```

## See Also

- [Quick Start Guide](../QUICKSTART.md)
- [Command Reference](../COMMANDS.md)
- [CLI README](../../README.md)

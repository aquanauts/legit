# Legit - Self-Hosted Git Server

Simple CLI for running your own Git server with Docker. No complex setup, no configuration files to edit - just install and run.

## Features

- 🚀 **5-minute setup** - Install script + `legit start` = running Git server
- 🔒 **Secure by default** - SSH public key authentication only
- 📦 **Multiple repositories** - Host unlimited Git repositories
- 🪝 **Git hooks support** - Full server-side hook support
- 🐳 **Runs in Docker** - Isolated, portable, easy to backup
- 🎯 **Simple CLI** - Intuitive commands, no Docker knowledge required

## Installation

### One-line install (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/USERNAME/legit/main/cli/install.sh | bash
```

### Manual install

```bash
# Download the CLI script
wget https://raw.githubusercontent.com/USERNAME/legit/main/cli/legit
chmod +x legit
sudo mv legit /usr/local/bin/

# Or install to user directory
mv legit ~/.local/bin/
```

## Quick Start

### 1. Start the server

```bash
legit start
```

On first run, legit will:
- Pull the Docker image from GitHub Container Registry
- Look for your SSH public key (or guide you to set one up)
- Start the Git server on port 2222

### 2. Create a repository

```bash
legit create-repo myproject
```

### 3. Clone and use

```bash
git clone ssh://git@localhost:2222/home/git/repos/myproject.git
cd myproject

# Add some content
echo "# My Project" > README.md
git add README.md
git commit -m "Initial commit"

# Push to your server
git push origin main
```

That's it! You now have a working Git server. 🎉

## Commands

```bash
legit start                # Start the Git server
legit stop                 # Stop the Git server
legit restart              # Restart the Git server
legit status               # Show server status
legit logs [-f]            # View server logs (-f to follow)
legit create-repo <name>   # Create a new repository
legit list-repos           # List all repositories
legit shell                # Open shell in container
legit pull [version]       # Pull new image version
legit version              # Show CLI and image versions
legit help                 # Show help message
```

## Configuration

Configuration file: `~/.config/legit/config`

```bash
# Example configuration
IMAGE=ghcr.io/username/legit-server:latest
CONTAINER_NAME=legit-server
SSH_PORT=2222
GIT_USER_UID=1000
GIT_USER_GID=1000
```

### Environment Variables

You can also configure via environment variables:

```bash
export LEGIT_IMAGE=ghcr.io/username/legit-server:v1.0.0
export LEGIT_SSH_PORT=2222
legit start
```

## SSH Key Setup

### Option 1: Use existing key (automatic)

If you have `~/.ssh/id_rsa.pub` or `~/.ssh/id_ed25519.pub`, legit will automatically use it.

### Option 2: Create a new key

```bash
ssh-keygen -t ed25519 -f ~/.ssh/legit_key -N ""
cp ~/.ssh/legit_key.pub ~/.config/legit/authorized_keys
```

### Option 3: Use GitHub keys

```bash
curl https://github.com/YOUR_USERNAME.keys > ~/.config/legit/authorized_keys
```

### Option 4: Multiple users

```bash
# Add multiple keys to authorized_keys
cat user1_key.pub >> ~/.config/legit/authorized_keys
cat user2_key.pub >> ~/.config/legit/authorized_keys
curl https://github.com/user3.keys >> ~/.config/legit/authorized_keys
```

## SSH Configuration (Optional)

Add to `~/.ssh/config` for easier access:

```
Host mygit
    HostName localhost
    Port 2222
    User git
    IdentityFile ~/.ssh/legit_key
```

Then clone with shorter syntax:

```bash
git clone mygit:/home/git/repos/myproject.git
```

## Remote Server Setup

To run on a remote server:

1. **Install legit on the server:**
   ```bash
   curl -fsSL https://raw.githubusercontent.com/USERNAME/legit/main/cli/install.sh | bash
   ```

2. **Start the server:**
   ```bash
   legit start
   ```

3. **Clone from your local machine:**
   ```bash
   git clone ssh://git@server.example.com:2222/home/git/repos/myproject.git
   ```

4. **Configure SSH (recommended):**
   ```
   # ~/.ssh/config
   Host gitserver
       HostName server.example.com
       Port 2222
       User git
   ```

   Then clone with:
   ```bash
   git clone gitserver:/home/git/repos/myproject.git
   ```

## Updating

To update to the latest version:

```bash
# Pull the latest image
legit pull latest

# Restart the server to use the new image
legit restart
```

## Backup and Restore

### Backup all repositories

```bash
# Using docker cp
docker cp legit-server:/home/git/repos ~/git-backup

# Or backup the volume
docker run --rm \
  -v git-repos:/data \
  -v $(pwd):/backup \
  ubuntu tar czf /backup/git-repos-$(date +%Y%m%d).tar.gz /data
```

### Restore repositories

```bash
# Copy backup to container
docker cp ~/git-backup/myproject.git legit-server:/home/git/repos/

# Fix permissions
legit shell
chown -R git:git /home/git/repos
```

## Troubleshooting

### Cannot connect via SSH?

```bash
# Check if server is running
legit status

# View logs
legit logs

# Test SSH connection
ssh -vvv -p 2222 git@localhost
```

### Permission denied (publickey)?

```bash
# Check authorized_keys
cat ~/.config/legit/authorized_keys

# Verify your public key is there
cat ~/.ssh/id_rsa.pub

# If not, add it
cp ~/.ssh/id_rsa.pub ~/.config/legit/authorized_keys
legit restart
```

### "Host key verification failed"?

```bash
# Remove old host key
ssh-keygen -R "[localhost]:2222"

# Or accept new key
ssh-keyscan -p 2222 localhost >> ~/.ssh/known_hosts
```

### Repository not found?

```bash
# List all repositories
legit list-repos

# Check repository exists
legit shell
ls -la /home/git/repos
```

## Documentation

- [Quick Start Guide](docs/QUICKSTART.md)
- [Command Reference](docs/COMMANDS.md)
- [Example Configurations](docs/examples/)

## Building Your Own Image

Want to customize the Docker image? See the [image builder documentation](../image/README.md).

## Contributing

Contributions welcome! Please see [CONTRIBUTING.md](../image/CONTRIBUTING.md) for guidelines.

## License

MIT License - see [LICENSE](../LICENSE) for details.

## Support

- **Issues**: [GitHub Issues](https://github.com/USERNAME/legit/issues)
- **Discussions**: [GitHub Discussions](https://github.com/USERNAME/legit/discussions)

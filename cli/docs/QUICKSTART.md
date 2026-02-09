# Quick Start Guide

Get your Git server running in 5 minutes using the `legit` CLI!

## Prerequisites

- Docker installed and running
- Git installed on your local machine
- SSH key pair (legit will help you set this up)

## Step 1: Install legit CLI

```bash
curl -fsSL https://raw.githubusercontent.com/USERNAME/legit/main/cli/install.sh | bash
```

This will:
- Download the `legit` CLI script
- Install it to `/usr/local/bin/legit`
- Create config directory at `~/.config/legit/`

## Step 2: Start the Server

```bash
legit start
```

On first run, legit will:
- Look for your SSH public key (`~/.ssh/id_rsa.pub` or `~/.ssh/id_ed25519.pub`)
- Copy it to `~/.config/legit/authorized_keys`
- Pull the Docker image from GitHub Container Registry
- Start the Git server on port 2222

**No SSH key?** legit will show you how to create one:
```bash
# Generate new key
ssh-keygen -t ed25519 -f ~/.ssh/legit_key -N ""

# Copy to config
cp ~/.ssh/legit_key.pub ~/.config/legit/authorized_keys

# Try again
legit start
```

## Step 3: Create a Repository

```bash
legit create-repo myproject
```

Output:
```
Creating repository: myproject
✓ Repository created: myproject.git

Clone with:
  git clone ssh://git@localhost:2222/srv/git/myproject.git
```

## Step 4: Clone and Use

```bash
# Clone the repository
git clone ssh://git@localhost:2222/srv/git/myproject.git
cd myproject

# Add some content
echo "# My Project" > README.md
git add README.md
git commit -m "Initial commit"

# Push to server
git push origin main
```

## Done! 🎉

Your Git server is now running and you've pushed your first commit.

## What's Next?

### Configure SSH (Optional but Recommended)

Add to `~/.ssh/config`:
```
Host mygit
    HostName localhost
    Port 2222
    User git
    IdentityFile ~/.ssh/legit_key
```

Now you can use shorter commands:
```bash
git clone mygit:/srv/git/myproject.git
git push mygit
git pull mygit
```

### Create More Repositories

```bash
legit create-repo website
legit create-repo api
legit create-repo docs

# List all repositories
legit list-repos
```

### Add More Users

Add their public keys to `~/.config/legit/authorized_keys`:

```bash
# Add from GitHub
curl https://github.com/teammate.keys >> ~/.config/legit/authorized_keys

# Or add manually
cat teammate_key.pub >> ~/.config/legit/authorized_keys

# Restart server to apply changes
legit restart
```

### View Server Logs

```bash
# View logs
legit logs

# Follow logs (live)
legit logs -f
```

## Common Commands

```bash
# Server management
legit start        # Start server
legit stop         # Stop server
legit restart      # Restart server
legit status       # Show status

# Repository management
legit create-repo <name>   # Create repository
legit list-repos           # List all repositories

# Maintenance
legit logs [-f]    # View logs
legit shell        # Open shell in container
legit pull         # Update to latest image
legit version      # Show version info
```

## Troubleshooting

### Can't connect via SSH?

```bash
# Check if server is running
legit status

# View logs for errors
legit logs

# Test SSH connection
ssh -vvv -p 2222 git@localhost
```

### Permission denied (publickey)?

```bash
# Check your authorized_keys
cat ~/.config/legit/authorized_keys

# Make sure your public key is there
cat ~/.ssh/id_rsa.pub

# If not, add it
cp ~/.ssh/id_rsa.pub ~/.config/legit/authorized_keys
legit restart
```

### "Host key verification failed"?

```bash
# Remove old host key
ssh-keygen -R "[localhost]:2222"

# Accept new key on next connection
```

### Container won't start?

```bash
# Check Docker is running
docker info

# View detailed logs
legit logs

# Open shell to debug
legit shell
```

## Remote Server Setup

To run on a remote server:

1. **Install legit on the server:**
   ```bash
   ssh user@server.example.com
   curl -fsSL https://raw.githubusercontent.com/USERNAME/legit/main/cli/install.sh | bash
   ```

2. **Setup SSH keys on the server:**
   ```bash
   # Copy your public key
   scp ~/.ssh/id_rsa.pub user@server.example.com:~/

   # On the server
   ssh user@server.example.com
   mkdir -p ~/.config/legit
   mv ~/id_rsa.pub ~/.config/legit/authorized_keys
   ```

3. **Start the server:**
   ```bash
   legit start
   ```

4. **On your local machine, add SSH config:**
   ```
   # ~/.ssh/config
   Host gitserver
       HostName server.example.com
       Port 2222
       User git
       IdentityFile ~/.ssh/id_rsa
   ```

5. **Clone from remote:**
   ```bash
   legit create-repo myproject  # On server
   git clone gitserver:/srv/git/myproject.git  # On local
   ```

## Backup Your Repositories

```bash
# Stop server
legit stop

# Backup repositories using Docker
docker run --rm \
  -v git-repos:/data \
  -v $(pwd):/backup \
  ubuntu tar czf /backup/git-backup-$(date +%Y%m%d).tar.gz /data

# Or copy directly
docker cp legit-server:/srv/git ~/git-backup

# Restart server
legit start
```

## Updating legit

To update to the latest version:

```bash
# Pull latest CLI (reinstall)
curl -fsSL https://raw.githubusercontent.com/USERNAME/legit/main/cli/install.sh | bash

# Pull latest Docker image
legit pull latest

# Restart
legit restart
```

## Next Steps

- Read the full [CLI README](../README.md)
- Check out the [Command Reference](COMMANDS.md)
- See [usage examples](examples/)

That's it! You're ready to use your own Git server. 🚀

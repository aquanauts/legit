# Quick Start Guide

Get your Git server running in 5 minutes!

## Prerequisites

- Docker installed and running
- Git installed on your local machine
- SSH key pair (or we'll create one)

## Step 1: Get Your SSH Key

### Option A: Use existing key
```bash
cp ~/.ssh/id_rsa.pub authorized_keys
```

### Option B: Create new key
```bash
ssh-keygen -t ed25519 -f ~/.ssh/git_server_key -N ""
cp ~/.ssh/git_server_key.pub authorized_keys
```

### Option C: Use GitHub keys
```bash
curl https://github.com/YOUR_USERNAME.keys > authorized_keys
```

## Step 2: Start the Server

```bash
docker run -d \
  --name git-server \
  -p 2222:22 \
  -v $(pwd)/authorized_keys:/home/git/.ssh/authorized_keys:ro \
  -v git-repos:/srv/git \
  -v ssh-host-keys:/etc/ssh/ssh_host_keys \
  git-server:latest
```

## Step 3: Create a Repository

```bash
docker exec git-server /usr/local/bin/init-repo.sh myproject
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
Host mygitserver
    HostName localhost
    Port 2222
    User git
    IdentityFile ~/.ssh/git_server_key
```

Now you can use shorter commands:
```bash
git clone mygitserver:/srv/git/myproject.git
```

### Add Git Hooks

```bash
# Copy example hook
docker cp examples/hooks/post-receive \
  git-server:/srv/git/myproject.git/hooks/

# Make it executable
docker exec git-server \
  chmod +x /srv/git/myproject.git/hooks/post-receive
```

### Create More Repositories

```bash
docker exec git-server /usr/local/bin/init-repo.sh another-project
git clone ssh://git@localhost:2222/srv/git/another-project.git
```

### Add More Users

Edit `authorized_keys` and restart:
```bash
curl https://github.com/teammate.keys >> authorized_keys
docker restart git-server
```

## Common Commands

```bash
# View logs
docker logs -f git-server

# List repositories
docker exec git-server ls -la /srv/git

# Backup repositories
docker cp git-server:/srv/git ./backup

# Stop server
docker stop git-server

# Stop and remove container
docker stop git-server && docker rm git-server

# Remove volumes
docker volume rm git-repos ssh-host-keys
```

## Troubleshooting

### Can't connect via SSH?
```bash
# Check container is running
docker ps

# Check logs
docker logs git-server

# Test SSH with verbose output
ssh -vvv -p 2222 git@localhost
```

### Permission denied?
```bash
# Check authorized_keys is mounted
docker exec git-server cat /home/git/.ssh/authorized_keys

# Check your local key
cat ~/.ssh/id_rsa.pub
```

### Need help?
See the full [README.md](README.md) for detailed documentation.

## Remote Server Setup

To use on a remote server:

1. **On the server:**
   ```bash
   # Build and run the container
   docker build -t git-server:latest .
   docker run -d \
     --name git-server \
     -p 2222:22 \
     -v $(pwd)/authorized_keys:/home/git/.ssh/authorized_keys:ro \
     -v git-repos:/srv/git \
     -v ssh-host-keys:/etc/ssh/ssh_host_keys \
     git-server:latest
   ```

2. **On your local machine:**
   ```bash
   # Replace server.example.com with your server's address
   git clone ssh://git@server.example.com:2222/srv/git/myproject.git
   ```

3. **Configure SSH (recommended):**
   ```
   # ~/.ssh/config
   Host gitserver
       HostName server.example.com
       Port 2222
       User git
       IdentityFile ~/.ssh/git_server_key
   ```

   Then clone with:
   ```bash
   git clone gitserver:/srv/git/myproject.git
   ```

That's it! You're ready to use your own Git server. 🚀

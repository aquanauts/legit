# Legit Command Reference

Complete reference for all `legit` CLI commands.

## Global Options

All commands use configuration from:
- Config file: `~/.config/legit/config`
- Environment variables: `LEGIT_*`

## Commands

### `legit start`

Start the Git server container.

**Usage:**
```bash
legit start
```

**Behavior:**
- Checks if Docker is installed and running
- Creates config directory if needed
- Looks for SSH keys (or prompts to set up)
- Pulls Docker image if not present
- Starts new container or restarts existing one
- Exposes SSH on configured port (default: 2222)

**First Run:**
On first run, `legit start` will:
1. Create `~/.config/legit/` directory
2. Look for `~/.ssh/id_rsa.pub` or `~/.ssh/id_ed25519.pub`
3. Copy found key to `~/.config/legit/authorized_keys`
4. If no key found, show setup instructions

**Example:**
```bash
$ legit start
Pulling image ghcr.io/username/legit-server:latest...
Starting new Git server container...
  Image: ghcr.io/username/legit-server:latest
  Container: legit-server
  SSH Port: 2222
✓ Git server started on port 2222

Next steps:
  Create a repository: legit create-repo myproject
  View logs: legit logs
```

---

### `legit stop`

Stop the Git server container.

**Usage:**
```bash
legit stop
```

**Behavior:**
- Stops running container
- Removes container (but keeps volumes)
- Preserves all repositories and SSH keys

**Example:**
```bash
$ legit stop
Stopping Git server...
✓ Git server stopped
```

**Note:** Volumes are preserved. Repositories and host keys remain intact.

---

### `legit restart`

Restart the Git server (stop + start).

**Usage:**
```bash
legit restart
```

**Behavior:**
- Equivalent to `legit stop && legit start`
- Useful after updating configuration
- Useful after pulling new image

**Example:**
```bash
$ legit restart
Stopping Git server...
✓ Git server stopped
Starting new Git server container...
✓ Git server started on port 2222
```

---

### `legit status`

Show the current status of the Git server.

**Usage:**
```bash
legit status
```

**Output:**
- Whether server is running
- Container details (if running)
- Status and port mapping

**Example:**
```bash
$ legit status
✓ Git server is running

NAMES         STATUS        PORTS
legit-server  Up 2 hours   0.0.0.0:2222->22/tcp
```

---

### `legit logs`

View server logs.

**Usage:**
```bash
legit logs [-f|--follow]
```

**Options:**
- `-f, --follow` - Follow log output (like `tail -f`)

**Examples:**
```bash
# View logs
legit logs

# Follow logs (live)
legit logs -f
legit logs --follow
```

**Output:**
Shows container logs including:
- SSH connection attempts
- Git operations
- Server startup messages
- Errors and warnings

---

### `legit create-repo`

Create a new Git repository.

**Usage:**
```bash
legit create-repo <name>
```

**Arguments:**
- `<name>` - Repository name (required)

**Behavior:**
- Creates bare repository at `/home/git/repos/<name>.git`
- Sets proper ownership (git:git)
- Makes repository ready for cloning

**Examples:**
```bash
$ legit create-repo myproject
Creating repository: myproject
Initialized empty Git repository in /home/git/repos/myproject.git/
✓ Repository created: myproject.git

Clone with:
  git clone ssh://git@localhost:2222/home/git/repos/myproject.git
```

**Clone URLs:**
- Standard: `ssh://git@localhost:2222/home/git/repos/myproject.git`
- SCP-style: `git@localhost:2222:/home/git/repos/myproject.git`
- With SSH config: `gitserver:/home/git/repos/myproject.git`

---

### `legit list-repos`

List all repositories on the server.

**Usage:**
```bash
legit list-repos
```

**Output:**
Shows all repositories in `/home/git/repos/` with:
- Permissions
- Owner
- Size
- Name

**Example:**
```bash
$ legit list-repos
Repositories:
total 16K
drwxr-xr-x 7 git git 4.0K Feb  9 12:00 myproject.git
drwxr-xr-x 7 git git 4.0K Feb  9 11:30 another-repo.git
drwxr-xr-x 7 git git 4.0K Feb  8 15:45 test.git
```

---

### `legit shell`

Open an interactive shell in the container.

**Usage:**
```bash
legit shell
```

**Behavior:**
- Opens bash shell as root user
- Useful for debugging
- Useful for manual operations

**Examples:**
```bash
$ legit shell
root@container:/# ls /home/git/repos
myproject.git  another-repo.git

root@container:/# cat /home/git/.ssh/authorized_keys
ssh-rsa AAAA...

root@container:/# exit
$
```

**Use Cases:**
- Check repository contents
- View SSH keys
- Debug permissions
- Install git hooks manually
- Inspect logs

---

### `legit pull`

Pull a new image version from registry.

**Usage:**
```bash
legit pull [version]
```

**Arguments:**
- `[version]` - Image tag to pull (default: `latest`)

**Examples:**
```bash
# Pull latest version
legit pull
legit pull latest

# Pull specific version
legit pull v1.0.0
legit pull edge
```

**After pulling:**
```bash
legit restart
```

**Version Tags:**
- `latest` - Latest stable release (recommended)
- `vX.Y.Z` - Specific version (e.g., v1.0.0)
- `edge` - Latest main branch (bleeding edge)

---

### `legit version`

Show CLI and image version information.

**Usage:**
```bash
legit version
```

**Output:**
```bash
$ legit version
legit CLI version: 1.0.0
Image: ghcr.io/username/legit-server:latest
Image created: 2026-02-09
```

---

### `legit help`

Show help message.

**Usage:**
```bash
legit help
legit --help
legit -h
```

**Output:**
Shows usage information and all available commands.

---

## Configuration

### Config File

Location: `~/.config/legit/config`

**Format:**
```bash
# Image to use
IMAGE=ghcr.io/username/legit-server:latest

# Container name
CONTAINER_NAME=legit-server

# SSH port on host
SSH_PORT=2222

# Git user UID/GID (optional)
GIT_USER_UID=1000
GIT_USER_GID=1000
```

### Environment Variables

All config options can be set via environment variables:

```bash
export LEGIT_IMAGE=ghcr.io/username/legit-server:v1.0.0
export LEGIT_SSH_PORT=2222
export LEGIT_CONTAINER=my-git-server
export LEGIT_GIT_USER_UID=$(id -u)
export LEGIT_GIT_USER_GID=$(id -g)

legit start
```

**Priority:**
1. Environment variables (`LEGIT_*`)
2. Config file (`~/.config/legit/config`)
3. Built-in defaults

---

## Common Workflows

### First Time Setup

```bash
# Install
curl -fsSL https://raw.githubusercontent.com/USERNAME/legit/main/cli/install.sh | bash

# Start server
legit start

# Create repository
legit create-repo myproject

# Clone
git clone ssh://git@localhost:2222/home/git/repos/myproject.git
```

### Daily Usage

```bash
# Create new repository
legit create-repo new-project

# List repositories
legit list-repos

# View logs
legit logs
```

### Updating

```bash
# Pull new image
legit pull latest

# Restart to use new image
legit restart

# Verify version
legit version
```

### Troubleshooting

```bash
# Check status
legit status

# View logs
legit logs -f

# Open shell for debugging
legit shell

# Restart server
legit restart
```

### Backup

```bash
# Stop server
legit stop

# Backup repositories
docker cp legit-server:/home/git/repos ~/git-backup

# Start server
legit start
```

---

## Exit Codes

- `0` - Success
- `1` - General error (command failed, Docker not installed, etc.)

---

## Files and Directories

### Config Directory

`~/.config/legit/`
- `config` - Configuration file
- `authorized_keys` - SSH public keys

### Docker Volumes

- `git-repos` - Mounted at `/home/git/repos` (repositories)
- `ssh-host-keys` - Mounted at `/etc/ssh/ssh_host_keys` (persistent host keys)

---

## SSH Configuration

For easier access, add to `~/.ssh/config`:

```
Host mygit
    HostName localhost
    Port 2222
    User git
    IdentityFile ~/.ssh/legit_key
```

Then use shorter commands:
```bash
git clone mygit:/home/git/repos/myproject.git
```

For remote servers:
```
Host gitserver
    HostName server.example.com
    Port 2222
    User git
    IdentityFile ~/.ssh/legit_key
```

```bash
git clone gitserver:/home/git/repos/myproject.git
```

---

## See Also

- [Quick Start Guide](QUICKSTART.md)
- [CLI README](../README.md)
- [Examples](examples/)

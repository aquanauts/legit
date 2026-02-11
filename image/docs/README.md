# Legit Server - Docker Image Builder

This directory contains the Docker image builder for the legit Git server.

## For End Users

**If you just want to run a Git server**, use the CLI wrapper instead:
👉 See [../cli/README.md](../cli/README.md)

The CLI provides a simpler interface and pulls pre-built images from GitHub Container Registry.

## For Image Builders

This section is for developers who want to:
- Build custom Docker images
- Modify the server configuration
- Contribute to the project
- Understand the internals

### Quick Build

```bash
cd image
make build
```

### Running Tests

```bash
cd image
make test
```

All tests should pass:
```
✓ All 10 integration tests passed
```

### Publishing Images

Images are automatically published to GitHub Container Registry (ghcr.io) via GitHub Actions.

**Automated publishing:**
- Push to `main` → Published as `edge` tag
- Push tag `vX.Y.Z` → Published as version tags

**Manual publishing:**
```bash
cd image
make publish DOCKER_TAG=v1.0.0
```

## Architecture

### Base Image
- **Ubuntu 24.04 LTS** - Long-term support, security updates

### Components
- **OpenSSH Server** - Public key authentication only
- **Git** - Full Git server functionality
- **git-shell** - Restricted shell environment for security

### File Structure
```
image/
├── Dockerfile              # Image definition
├── docker-entrypoint.sh    # Container startup script
├── init-repo.sh            # Repository creation script
├── sshd_config            # SSH server configuration
├── test-setup.sh          # Integration tests
├── Makefile               # Build automation
└── examples/              # Example git hooks
    └── hooks/
        ├── post-receive
        ├── pre-receive
        └── update
```

### Volumes

The image expects three volumes:

1. **`/home/git/repos`** - Git repositories (required)
2. **`/home/git/.ssh/authorized_keys`** - SSH public keys (required)
3. **`/etc/ssh/ssh_host_keys`** - Persistent SSH host keys (recommended)

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `GIT_USER_UID` | Set git user's UID (for permission matching) | - |
| `GIT_USER_GID` | Set git user's GID | - |
| `SSH_AUTHORIZED_KEYS_URL` | Fetch keys from URL (e.g., GitHub) | - |

### Exposed Ports

- **22/tcp** - SSH server (map to host port 2222 or other)

## Development

### Building Locally

From the repository root:
```bash
make build
```

Or from the image directory:
```bash
cd image
make build
```

This creates `legit-server:latest` image.

### Build Without Cache

```bash
make dev-build
```

### Running Tests

```bash
make test
```

Tests verify:
- Container starts successfully
- SSH authentication works
- Repository creation works
- Git clone/push operations work
- Environment variables are respected
- Permissions are correct
- Host keys persist across restarts

### Validating Changes

```bash
make validate
```

Checks:
- Dockerfile syntax
- Shell script syntax (bash -n)

### Development Workflow

1. Make changes to Dockerfile or scripts
2. Build: `make build`
3. Test: `make test`
4. Validate: `make validate`
5. Commit and push

### Installing Pre-commit Hooks

From the repository root:
```bash
make hooks
```

This installs pre-commit hooks that run before each commit across the entire repository.

## Manual Testing

### Build and Run

```bash
# Build image
cd image
make build

# Create authorized_keys
cp ~/.ssh/id_rsa.pub authorized_keys

# Run container
docker run -d \
  --name legit-server-dev \
  -p 2222:22 \
  -v $(pwd)/authorized_keys:/home/git/.ssh/authorized_keys:ro \
  -v git-repos-dev:/home/git/repos \
  -v ssh-host-keys-dev:/etc/ssh/ssh_host_keys \
  legit-server:latest

# Create a test repository
docker exec legit-server-dev /usr/local/bin/init-repo.sh test

# Clone it
git clone ssh://git@localhost:2222/home/git/repos/test.git

# Test push
cd test
echo "test" > README.md
git add README.md
git commit -m "test"
git push

# Cleanup
docker stop legit-server-dev
docker rm legit-server-dev
docker volume rm git-repos-dev ssh-host-keys-dev
```

### Testing Environment Variables

```bash
docker run -d \
  --name legit-server-test \
  -p 2222:22 \
  -e GIT_USER_UID=$(id -u) \
  -e GIT_USER_GID=$(id -g) \
  -v $(pwd)/authorized_keys:/home/git/.ssh/authorized_keys:ro \
  -v git-repos-test:/home/git/repos \
  -v ssh-host-keys-test:/etc/ssh/ssh_host_keys \
  legit-server:latest
```

## Security

### What's Secured

✅ **Public key authentication only** - No password auth
✅ **git-shell restriction** - Users cannot execute arbitrary commands
✅ **Root login disabled** - Root cannot connect via SSH
✅ **Limited user access** - Only git user can connect
✅ **No port forwarding** - X11, TCP, agent forwarding disabled
✅ **Minimal packages** - Only essential packages installed
✅ **Proper permissions** - Restricted file permissions
✅ **Non-root operations** - Git operations run as non-root user

### Security Testing

```bash
# Test that password auth is disabled
ssh -o PubkeyAuthentication=no -p 2222 git@localhost
# Should fail: "Permission denied (publickey)"

# Test that shell is restricted
ssh -p 2222 git@localhost "whoami"
# Should show: "fatal: Interactive git shell is not enabled"

# Test that arbitrary commands fail
ssh -p 2222 git@localhost "cat /etc/passwd"
# Should be rejected
```

## Publishing Strategy

### Registry
GitHub Container Registry (ghcr.io)

### Image Name
`ghcr.io/USERNAME/legit-server`

### Tags
- `latest` - Latest stable release (recommended)
- `vX.Y.Z` - Specific version (e.g., v1.0.0)
- `vX.Y` - Minor version (e.g., v1.0)
- `vX` - Major version (e.g., v1)
- `edge` - Latest main branch (bleeding edge)

### Publishing Process

**Automated (GitHub Actions):**
```bash
# Create a release
git tag v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0

# GitHub Actions will:
# 1. Run tests
# 2. Build image
# 3. Push to ghcr.io with multiple tags
```

**Manual:**
```bash
cd image
make publish DOCKER_TAG=v1.0.0
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development guidelines.

### Key Guidelines

- All shell scripts must pass `shellcheck`
- All changes must pass integration tests
- Update tests when adding new features
- Follow existing code style
- Document environment variables
- Update README for user-facing changes

## Testing Guide

See [TESTING.md](TESTING.md) for detailed testing documentation.

## Architecture Details

See [ARCHITECTURE.md](ARCHITECTURE.md) for implementation details.

## Makefile Targets

```bash
make help              # Show all targets
make build             # Build Docker image
make dev-build         # Build without cache
make test              # Run integration tests
make validate          # Validate Dockerfile and scripts
make publish           # Tag and push to registry
make hooks             # Install pre-commit hooks
make pre-commit        # Run pre-commit checks
make clean             # Remove build artifacts
```

## License

MIT License - see [../LICENSE](../LICENSE) for details.

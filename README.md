# Legit - Self-Hosted Git Server

A simple, secure, self-hosted Git server that runs in Docker. No complex configuration, no database setup - just install and run.

## Project Structure

This is a monorepo containing two main components:

### 🎯 [CLI Tool](cli/) - For End Users

Simple command-line tool for running the Git server. **Start here if you just want to use a Git server.**

```bash
# Install
curl -fsSL https://raw.githubusercontent.com/USERNAME/legit/main/cli/install.sh | bash

# Start
legit start

# Create repository
legit create-repo myproject

# Clone
git clone ssh://git@localhost:2222/srv/git/myproject.git
```

**Features:**
- 5-minute setup
- No Docker knowledge required
- Simple CLI commands
- Automatic image updates
- [Read more →](cli/README.md)

### 🔧 [Docker Image](image/) - For Contributors

Docker image builder and development tools. **Start here if you want to customize the image or contribute.**

```bash
cd image
make build
make test
make publish
```

**Features:**
- Ubuntu 24.04 LTS base
- SSH + Git server
- Automated CI/CD
- Comprehensive tests
- [Read more →](image/README.md)

## Quick Start (End Users)

### Installation

```bash
curl -fsSL https://raw.githubusercontent.com/USERNAME/legit/main/cli/install.sh | bash
```

### Usage

```bash
# Start server
legit start

# Create repository
legit create-repo myproject

# Clone and use
git clone ssh://git@localhost:2222/srv/git/myproject.git
cd myproject
echo "# My Project" > README.md
git add README.md
git commit -m "Initial commit"
git push origin main
```

For detailed usage, see [CLI Documentation](cli/README.md).

## Quick Start (Contributors)

### Build Image

```bash
cd image
make build
make test
```

### Run Locally

```bash
# Create authorized_keys with your public key
cp ~/.ssh/id_rsa.pub authorized_keys

# Start container
docker run -d \
  --name legit-server \
  -p 2222:22 \
  -v $(pwd)/authorized_keys:/home/git/.ssh/authorized_keys:ro \
  -v git-repos:/srv/git \
  -v ssh-host-keys:/etc/ssh/ssh_host_keys \
  legit-server:latest
```

For detailed development instructions, see [Image Documentation](image/README.md).

## Features

### Security
- 🔒 SSH public key authentication only (no passwords)
- 🐚 Restricted git-shell environment (no arbitrary command execution)
- 🚫 Root login disabled
- 🔐 Minimal attack surface

### Usability
- 🚀 5-minute setup with CLI tool
- 📦 Multiple repository support
- 🪝 Full git hooks support
- 🔄 Persistent data with Docker volumes
- 📊 Easy backup and restore

### Operations
- 🐳 Runs in Docker container
- 📈 Resource limits configurable
- 📝 Comprehensive logging
- 🔍 Health monitoring
- ⚡ Fast and lightweight

## Use Cases

### Personal Projects
Host your personal Git repositories without relying on external services.

### Team Collaboration
Run a private Git server for your team with SSH key-based access.

### CI/CD Integration
Use as a Git source for your CI/CD pipelines.

### Development Environment
Quick Git server for testing and development.

### Air-gapped Environments
Run Git server in isolated networks without internet access.

## Documentation

### For Users
- [CLI README](cli/README.md) - User-focused documentation
- [Quick Start Guide](cli/docs/QUICKSTART.md) - Get started in 5 minutes
- [Command Reference](cli/docs/COMMANDS.md) - All CLI commands
- [Examples](cli/docs/examples/) - Common usage patterns

### For Contributors
- [Image README](image/README.md) - Image builder documentation
- [Contributing Guide](image/CONTRIBUTING.md) - Development guidelines
- [Testing Guide](image/TESTING.md) - Testing documentation
- [Architecture](image/ARCHITECTURE.md) - Implementation details

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    End User                             │
│                       ↓                                 │
│              legit CLI (Bash)                          │
│                       ↓                                 │
│              Docker Container                           │
│         ┌──────────────────────────┐                   │
│         │   OpenSSH Server         │                   │
│         │   git-shell restriction  │                   │
│         │   Git repositories       │                   │
│         └──────────────────────────┘                   │
│                       ↓                                 │
│              Docker Volumes                             │
│         ┌──────────────────────────┐                   │
│         │   /srv/git               │ ← Repositories    │
│         │   /home/git/.ssh         │ ← SSH keys        │
│         │   /etc/ssh/ssh_host_keys │ ← Host keys       │
│         └──────────────────────────┘                   │
└─────────────────────────────────────────────────────────┘
```

## Requirements

### For End Users (CLI)
- Docker installed and running
- Git installed
- SSH key pair
- Bash shell
- curl (for installation)

### For Contributors (Image Building)
- Docker
- GNU Make
- Bash 4.0+
- Git

## Comparison with Other Solutions

### vs. GitHub/GitLab
- ✅ Self-hosted, full control
- ✅ No external dependencies
- ✅ Simple setup
- ❌ No web UI
- ❌ No issue tracking

### vs. Gitolite
- ✅ Simpler setup
- ✅ Docker-based
- ✅ Modern tooling
- ❌ Less granular permissions

### vs. GitLab/Gitea (self-hosted)
- ✅ Much lighter weight
- ✅ Faster setup
- ✅ Lower resource usage
- ❌ No web UI
- ❌ Fewer features

**Use Legit when:** You want a simple, lightweight Git server without web UI or complex features.

## Roadmap

- [ ] Web UI for repository browsing
- [ ] Repository access control (per-repo permissions)
- [ ] Webhook support
- [ ] Git LFS support
- [ ] Repository mirroring
- [ ] Metrics and monitoring
- [ ] Windows support for CLI

## Contributing

We welcome contributions! See [CONTRIBUTING.md](image/CONTRIBUTING.md) for guidelines.

### Ways to Contribute
- 🐛 Report bugs
- 💡 Suggest features
- 📝 Improve documentation
- 🔧 Submit pull requests
- ⭐ Star the repository

## Support

- **Issues**: [GitHub Issues](https://github.com/USERNAME/legit/issues)
- **Discussions**: [GitHub Discussions](https://github.com/USERNAME/legit/discussions)
- **Security**: See [SECURITY.md](SECURITY.md) for reporting vulnerabilities

## License

MIT License - see [LICENSE](LICENSE) for details.

## Acknowledgments

Built with:
- [Ubuntu](https://ubuntu.com/) - Base operating system
- [OpenSSH](https://www.openssh.com/) - SSH server
- [Git](https://git-scm.com/) - Version control
- [Docker](https://www.docker.com/) - Containerization

Inspired by:
- [Git Book - Git on the Server](https://git-scm.com/book/en/v2/Git-on-the-Server-Setting-Up-the-Server)
- [rockstorm101/git-server-docker](https://github.com/rockstorm101/git-server-docker)

## Authors

Created and maintained by the Legit contributors.

---

**Ready to get started?**
- End users: [Install the CLI →](cli/README.md)
- Contributors: [Build the image →](image/README.md)

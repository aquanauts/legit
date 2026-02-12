# Legit - Self-Hosted Git Server

A simple, secure, agent-friendly Git server that runs in Docker. No complex configuration, no database setup - just install and run.

## Quick Start

On a remote host where you have Docker installed, run the following:

```bash
# Install
wget https://raw.githubusercontent.com/aquanauts/legit/main/cli/legit && chmod +x legit

# Start
legit
```

Then, from your development machine, push a repository:

```bash
git push ssh://git@my.remote.host:2222/legit main
```

## Configuration

### Environment Variables

Legit pulls configuration options from [environment variables](cli/legit#L4). Some existing variables include:

* `LEGIT_IMAGE` - Docker image to use (default: `ghcr.io/aquanauts/legit-server:latest`)
* `LEGIT_SSH_PORT` - SSH server port (default: `2222`)
* `LEGIT_HOME` - Home directory for Legit data (default: `~/.legit`)
* `LEGIT_AUTHORIZED_KEYS` - An ssh authorized_keys file to use for git and root access (default $HOME/.ssh/authorized_keys)
* `LEGIT_MOUNT_DIRS` - Colon-separated list of directories to mount into the container at `/home/git/<basename>`

### Command Line Options

* `--interactive` - Run container in foreground mode (default: detached mode). Press CTRL+C to stop.

## Examples

### Claude Code Agent

### Continuous Integration

## For Contributors

Docker image tasks are managed by a [Makefile](image/Makefile)

```console
% cd image
% make
help                           Show this help message
docker-daemon                  Start Docker daemon (via Colima if needed)
docker-daemon-clean            Stop and clean Docker daemon
build                          Build the Docker image
dev-build                      Build without cache for development
publish                        Tag and push image to registry
publish-latest                 Publish as latest tag
clean                          Remove build artifacts and tools
```

# Legit - Self-Hosted Git Server

A simple, secure, agent-friendly Git server that runs in Docker. No complex configuration, no database setup - just install and run.

## Quick Start

The Legit container is intended to be run on a remote Linux host where you have Docker installed. SSH to that machine and run:

```bash
# Install
wget https://raw.githubusercontent.com/aquanauts/legit/main/cli/legit && chmod +x legit

# Start
legit
```

Then, from a repository on your development machine, push a branch (`main` in this case):

```bash
git push ssh://git@<your remote hostname here>:2222/legit main
```

## Interactive mode

By default, the Legit container runs in the background. If you're trying to troubleshoot authentication errors, it can sometimes be useful to run it in interactive mode, so you can easily see the sshd logs.

```bash
legit --interactive
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

### Post-Receive Hook

After a change is pushed to the repository, Legit will look for a file named `.legit_post_receive` in the root of the repository (Example [here](.legit_post_receive)). If Legit finds this file, and it's executable, it will run it. This allows us to do some interesting things.

## Examples

### Continuous Integration

The `.legit_post_receive` is run in a freshly cloned copy of the repository, with the branch that was pushed checked out. So just running the tests in this script gives us a tiny continuous integration server based into our git repo.

### Claude Code Agent

```bash
if ! which claude; then
  echo "Claude not found, installing"
  curl -fsSL https://claude.ai/install.sh | bash
fi

if ! tmux has-session -t claude-orchestrator 2>/dev/null; then
  # Note: To make this work, you'll need Claude credentials. One option is to mount the .claude directory by setting LEGIT_MOUNT_DIRS, like so:
  # LEGIT_MOUNT_DIRS=$HOME/.claude legit
  tmux new-session -d -s claude-orchestrator "claude --dangerously-skip-permissions"
fi

tmux send-keys -t claude-orchestrator "Inspect the code in $(pwd) for TODO comments and fix them. Commit each fix one at a time and push it up to the remote origin."
tmux send-keys -t claude-orchestrator Enter
```

## Shell Access

While you can also use `docker exec`, it's sometime useful to be able to ssh into this server (to inspect our Claude tmux session, for example). To do this, you can connect as the `root` user. This uses the same authorized_keys provided for the git user.

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

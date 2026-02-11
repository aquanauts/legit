#!/bin/bash
set -e

echo "=== Git Server Initialization ==="

# Adjust git user UID/GID if environment variables are set
if [ -n "$GIT_USER_UID" ] || [ -n "$GIT_USER_GID" ]; then
    CURRENT_UID=$(id -u git)
    CURRENT_GID=$(id -g git)
    NEW_UID=${GIT_USER_UID:-$CURRENT_UID}
    NEW_GID=${GIT_USER_GID:-$CURRENT_GID}

    if [ "$CURRENT_UID" != "$NEW_UID" ] || [ "$CURRENT_GID" != "$NEW_GID" ]; then
        echo "Adjusting git user UID:GID from $CURRENT_UID:$CURRENT_GID to $NEW_UID:$NEW_GID"

        # Change group ID if needed
        if [ "$CURRENT_GID" != "$NEW_GID" ]; then
            groupmod -g "$NEW_GID" git
        fi

        # Change user ID if needed
        if [ "$CURRENT_UID" != "$NEW_UID" ]; then
            usermod -u "$NEW_UID" git
        fi

        # Update ownership of git's files
        echo "Updating file ownership (this may take a moment)..."
        chown -R git:git /home/git /home/git/repos 2>/dev/null || true
    fi
fi

# Generate SSH host keys if they don't exist
echo "Checking SSH host keys..."
if [ ! -f /etc/ssh/ssh_host_keys/ssh_host_rsa_key ]; then
    echo "Generating RSA host key..."
    ssh-keygen -t rsa -b 4096 -f /etc/ssh/ssh_host_keys/ssh_host_rsa_key -N "" -q
fi

if [ ! -f /etc/ssh/ssh_host_keys/ssh_host_ecdsa_key ]; then
    echo "Generating ECDSA host key..."
    ssh-keygen -t ecdsa -b 521 -f /etc/ssh/ssh_host_keys/ssh_host_ecdsa_key -N "" -q
fi

if [ ! -f /etc/ssh/ssh_host_keys/ssh_host_ed25519_key ]; then
    echo "Generating Ed25519 host key..."
    ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_keys/ssh_host_ed25519_key -N "" -q
fi

echo "SSH host keys ready"

# Check if authorized_keys has any keys
if [ ! -s /root/git_authorized_keys ]; then
    echo ""
    echo "ERROR: No SSH keys found in /root/git_authorized_keys"
    echo "You will not be able to connect until you add SSH public keys."
    echo ""
    echo "To add keys mount this file: -v /\$HOME/.ssh/authorized_keys:/root/git_authorized_keys:ro"
    echo ""
    exit 1
fi

# Determine mode (headless or interactive)
MODE="${LEGIT_MODE:-headless}"

if [ "$MODE" = "headless" ]; then
    echo "Starting SSH daemon..."
    exec /usr/sbin/sshd -D -e
else
    # Interactive mode - run sshd in background, then start tmux
    echo "Starting SSH daemon in background..."
    /usr/sbin/sshd

    echo ""
    echo "Starting tmux session as git user..."
    echo "Tip: Use 'Ctrl+B, D' to detach (keeps server running)"
    echo "     Use 'exit' to stop the server"
    echo ""
    exec sudo -u git tmux new-session -s legit -c /home/git /bin/bash
fi

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
        chown -R git:git /home/git /srv/git 2>/dev/null || true
    fi
fi

# SSH host keys are baked into the image
echo "SSH host keys ready"

# Fetch authorized_keys from URL if environment variable is set
if [ -n "$SSH_AUTHORIZED_KEYS_URL" ]; then
    echo "Fetching authorized_keys from $SSH_AUTHORIZED_KEYS_URL"
    if curl -fsSL "$SSH_AUTHORIZED_KEYS_URL" -o /home/git/.ssh/authorized_keys; then
        echo "Successfully fetched authorized_keys"
        chmod 600 /home/git/.ssh/authorized_keys
        chown git:git /home/git/.ssh/authorized_keys
    else
        echo "Warning: Failed to fetch authorized_keys from URL"
    fi
fi

# Create symlink from /home/git/repos to /srv/git if requested
if [ "$REPOSITORIES_HOME_LINK" = "true" ]; then
    if [ ! -e /home/git/repos ]; then
        echo "Creating symlink /home/git/repos -> /srv/git"
        ln -s /srv/git /home/git/repos
        chown -h git:git /home/git/repos
    fi
fi

# Ensure proper permissions on SSH directory and authorized_keys
echo "Setting SSH directory permissions..."
chmod 700 /home/git/.ssh
if [ -f /home/git/.ssh/authorized_keys ]; then
    # Only try to set permissions if the file is writable (not mounted read-only)
    if [ -w /home/git/.ssh/authorized_keys ]; then
        chmod 600 /home/git/.ssh/authorized_keys
        chown git:git /home/git/.ssh/authorized_keys
    fi
fi
chown git:git /home/git/.ssh

# Check if authorized_keys has any keys
if [ ! -s /home/git/.ssh/authorized_keys ]; then
    echo ""
    echo "ERROR: No SSH keys found in /home/git/.ssh/authorized_keys"
    echo "You will not be able to connect until you add SSH public keys."
    echo ""
    echo "To add keys, either:"
    echo "  1. Mount a file: -v /\$HOME/.ssh/authorized_keys:/home/git/.ssh/authorized_keys:ro"
    echo "  2. Set SSH_AUTHORIZED_KEYS_URL environment variable (e.g., https://github.com/username.keys)"
    echo ""
    exit 1
fi

# Display server information
echo ""
echo "=== Git Server Ready ==="
echo "Repositories directory: /srv/git"
echo "SSH user: git"
echo "SSH shell: $(getent passwd git | cut -d: -f7)"
echo "To create a repository: docker exec <container> /usr/local/bin/init-repo.sh <repo-name>"
echo "To clone: git clone ssh://git@<host>:<port>/srv/git/<repo-name>.git"
echo ""

# Start SSH daemon in foreground
echo "Starting SSH daemon..."
exec /usr/sbin/sshd -D -e

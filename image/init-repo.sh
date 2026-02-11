#!/bin/bash
set -e

# Repository initialization helper script
# Usage: init-repo.sh <repository-name>

if [ $# -eq 0 ]; then
    echo "Error: No repository name provided"
    echo "Usage: $0 <repository-name>"
    echo ""
    echo "Example: $0 myproject"
    echo "This will create: /home/git/repos/myproject.git"
    exit 1
fi

REPO_NAME="$1"
REPO_DIR="/home/git/repos/${REPO_NAME}.git"

# Check if repository already exists
if [ -d "$REPO_DIR" ]; then
    echo "Error: Repository already exists at $REPO_DIR"
    exit 1
fi

# Create the repository
echo "Creating bare git repository: $REPO_DIR"
git init --bare --shared=group "$REPO_DIR"

# Set ownership to git user
chown -R git:git "$REPO_DIR"

# Set proper permissions
chmod -R 755 "$REPO_DIR"
chmod -R g+w "$REPO_DIR"

echo ""
echo "Repository created successfully!"
echo ""
echo "Clone with:"
echo "  git clone ssh://git@<host>:<port>/home/git/repos/${REPO_NAME}.git"
echo ""

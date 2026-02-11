# Example Git Hooks

This directory contains example server-side git hooks that you can use with your git server.

## Available Hooks

### post-receive

Runs **after** refs have been updated in the repository. Perfect for:
- Notifications (Slack, email, etc.)
- Triggering deployments
- Logging push events
- Starting CI/CD pipelines

**Cannot reject pushes** - code has already been accepted.

### pre-receive

Runs **before** refs are updated. Perfect for:
- Validating commit messages
- Checking file sizes
- Detecting sensitive files
- Enforcing branch policies
- Running tests

**Can reject pushes** by exiting with non-zero status.

### update

Runs **once per branch** being updated (whereas pre-receive runs once for all refs). Perfect for:
- Per-branch policies
- Preventing branch deletion
- Enforcing fast-forward merges
- Branch naming conventions

**Can reject updates** for specific branches by exiting with non-zero status.

## Usage

### Option 1: Copy hooks into container

```bash
# Copy hook to repository
docker cp examples/hooks/post-receive git-server:/home/git/repos/myrepo.git/hooks/

# Make executable and set ownership
docker exec git-server chmod +x /home/git/repos/myrepo.git/hooks/post-receive
docker exec git-server chown git:git /home/git/repos/myrepo.git/hooks/post-receive
```

### Option 2: Create inside container

```bash
docker exec git-server bash -c 'cat > /home/git/repos/myrepo.git/hooks/post-receive << "EOF"
#!/bin/bash
echo "Push received at $(date)"
EOF'

docker exec git-server chmod +x /home/git/repos/myrepo.git/hooks/post-receive
```

## Customizing Hooks

These examples are templates - edit them to fit your needs:

1. **Copy the hook you want to customize**
   ```bash
   cp examples/hooks/post-receive my-post-receive
   ```

2. **Edit the hook** - uncomment or add features you need

3. **Deploy the hook** using one of the methods above

## Hook Environment

Hooks run with these characteristics:
- **User**: `git`
- **Working directory**: Repository directory (e.g., `/home/git/repos/myrepo.git`)
- **Standard input**: For receive hooks, receives: `<old-sha1> <new-sha1> <ref-name>`
- **Exit code**: Non-zero rejects the operation (pre-receive, update only)

## Common Patterns

### Send Slack notification

```bash
#!/bin/bash
SLACK_WEBHOOK="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"

while read oldrev newrev refname; do
    branch=$(echo "$refname" | sed 's|refs/heads/||')
    message=$(git log -1 --pretty=format:'%s' $newrev)

    curl -X POST -H 'Content-type: application/json' \
        --data "{\"text\":\"Push to $branch: $message\"}" \
        "$SLACK_WEBHOOK"
done
```

### Deploy on push to main

```bash
#!/bin/bash
DEPLOY_DIR=/var/www/myapp

while read oldrev newrev refname; do
    if [[ $refname == "refs/heads/main" ]]; then
        echo "Deploying to production..."
        GIT_WORK_TREE=$DEPLOY_DIR git checkout -f main
        echo "Deployed commit: $newrev"
    fi
done
```

### Enforce commit message format

```bash
#!/bin/bash
while read oldrev newrev refname; do
    for commit in $(git rev-list $oldrev..$newrev); do
        message=$(git log -1 --pretty=format:'%s' $commit)

        # Require format: "TYPE: description" (e.g., "feat: add login")
        if ! echo "$message" | grep -qE '^(feat|fix|docs|style|refactor|test|chore): '; then
            echo "ERROR: Invalid commit message format"
            echo "Commit: $commit"
            echo "Message: $message"
            echo "Required format: 'type: description'"
            echo "Types: feat, fix, docs, style, refactor, test, chore"
            exit 1
        fi
    done
done
```

### Prevent large files

```bash
#!/bin/bash
MAX_SIZE=$((50 * 1024 * 1024)) # 50MB

while read oldrev newrev refname; do
    for commit in $(git rev-list $oldrev..$newrev); do
        for file in $(git diff-tree --no-commit-id --name-only -r $commit); do
            size=$(git cat-file -s "$commit:$file" 2>/dev/null || echo 0)
            if [ "$size" -gt "$MAX_SIZE" ]; then
                echo "ERROR: File too large: $file ($(numfmt --to=iec $size))"
                echo "Maximum: $(numfmt --to=iec $MAX_SIZE)"
                exit 1
            fi
        done
    done
done
```

## Testing Hooks

### Test locally before deploying

```bash
# Make a test repository
mkdir test-repo && cd test-repo
git init

# Copy hook
cp ../examples/hooks/pre-receive .git/hooks/

# Make executable
chmod +x .git/hooks/pre-receive

# Test by making a commit
echo "test" > file.txt
git add file.txt
git commit -m "test"
```

### Test in container

```bash
# Deploy hook
docker cp examples/hooks/post-receive git-server:/home/git/repos/test.git/hooks/
docker exec git-server chmod +x /home/git/repos/test.git/hooks/post-receive

# Make a test push
cd test-repo
echo "test" >> file.txt
git commit -am "Test hook"
git push origin main  # Watch for hook output
```

### Debug hooks

Add debug output to your hooks:

```bash
#!/bin/bash
set -x  # Enable command tracing

echo "Hook started at $(date)" >&2
echo "Arguments: $@" >&2
echo "Working directory: $(pwd)" >&2
echo "User: $(whoami)" >&2

# Your hook code here...
```

## Resources

- [Git Hooks Documentation](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks)
- [Git Hook Examples](https://github.com/git/git/tree/master/templates)
- [Server-side Hooks](https://git-scm.com/book/en/v2/Customizing-Git-An-Example-Git-Enforced-Policy)

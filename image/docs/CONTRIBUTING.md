# Contributing to Git Server Docker

Thank you for your interest in contributing! This document provides guidelines and information for contributors.

## How to Contribute

### Reporting Issues

- Check existing issues before creating a new one
- Use the issue template if available
- Include version information (Docker, OS, git version)
- Provide clear steps to reproduce
- Include relevant logs and error messages

### Suggesting Features

- Check if the feature has already been requested
- Clearly describe the use case and benefits
- Consider if the feature fits the project scope
- Be open to discussion about implementation

### Submitting Pull Requests

1. **Fork the repository** and create a feature branch
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes** following the coding standards below

3. **Test your changes** thoroughly
   ```bash
   ./test-setup.sh
   ```

4. **Commit with clear messages**
   ```bash
   git commit -m "feat: add new feature description"
   ```
   Use conventional commit format:
   - `feat:` - New feature
   - `fix:` - Bug fix
   - `docs:` - Documentation changes
   - `refactor:` - Code refactoring
   - `test:` - Test additions or changes
   - `chore:` - Maintenance tasks

5. **Push and create a pull request**
   ```bash
   git push origin feature/your-feature-name
   ```

## Coding Standards

### Shell Scripts

- Use `#!/bin/bash` shebang
- Enable strict mode: `set -e` (exit on error)
- Quote variables: `"$VARIABLE"` not `$VARIABLE`
- Use meaningful variable names
- Add comments for complex logic
- Check exit codes for critical commands

### Dockerfile

- Use official base images
- Combine RUN commands to reduce layers
- Clean up in the same layer as installation
- Use specific versions when possible
- Add comments for complex steps
- Follow Docker best practices

### Documentation

- Keep README.md up to date
- Use clear, concise language
- Include examples for new features
- Update relevant sections when changing behavior
- Check for typos and formatting

## Testing

### Manual Testing

1. Build the image:
   ```bash
   docker build -t git-server:test .
   ```

2. Run the test script:
   ```bash
   ./test-setup.sh
   ```

3. Test specific scenarios:
   - SSH key authentication
   - Repository creation and cloning
   - Git hooks functionality
   - Volume persistence
   - Permission handling

### Test Checklist

- [ ] Docker image builds without errors
- [ ] Container starts successfully
- [ ] SSH connection works with public key
- [ ] Password authentication is blocked
- [ ] git-shell restricts to git commands only
- [ ] Repository creation works
- [ ] Git clone/push/pull operations work
- [ ] Git hooks execute properly
- [ ] Volume mounts work correctly
- [ ] Environment variables work as expected
- [ ] Documentation is accurate

## Project Structure

```
.
├── Dockerfile              # Main Docker image definition
├── docker-entrypoint.sh    # Container initialization script
├── init-repo.sh           # Repository creation helper
├── sshd_config            # SSH server configuration
├── test-setup.sh          # Automated test script
├── README.md              # Main documentation
├── CONTRIBUTING.md        # This file
├── LICENSE                # MIT license
├── .dockerignore          # Files to exclude from build
├── .gitignore             # Git ignore rules
├── authorized_keys.example # Example SSH keys file
└── examples/
    ├── README.md          # Examples documentation
    └── hooks/             # Example git hooks
        ├── post-receive
        ├── pre-receive
        └── update
```

## Development Workflow

### Setting Up Development Environment

```bash
# Clone the repository
git clone <repository-url>
cd git-server-docker

# Create a feature branch
git checkout -b feature/my-feature

# Make changes...

# Test locally
./test-setup.sh

# Build and test manually
docker build -t git-server:dev .
docker run -d --name test-server git-server:dev
# ... test commands ...
docker stop test-server && docker rm test-server
```

### Common Development Tasks

**Add a new environment variable:**
1. Update `docker-entrypoint.sh` to handle the variable
2. Document it in `README.md` (Configuration section)
3. Add example usage to `README.md`
4. Test it works as expected

**Modify SSH configuration:**
1. Update `sshd_config`
2. Test the configuration: `docker exec container sshd -t`
3. Document any behavior changes in `README.md`
4. Update security section if relevant

**Add a new feature:**
1. Discuss in an issue first (for major features)
2. Implement the feature
3. Add tests (update `test-setup.sh` if needed)
4. Document in `README.md`
5. Add examples if applicable
6. Submit pull request

## Release Process

(For maintainers)

1. Update version in relevant files
2. Update CHANGELOG.md (if exists)
3. Test thoroughly
4. Create git tag: `git tag -a v1.0.0 -m "Release 1.0.0"`
5. Push tag: `git push origin v1.0.0`
6. Build and push Docker image
7. Create GitHub release with notes

## Community

- Be respectful and constructive
- Help others when you can
- Follow the code of conduct
- Ask questions if something is unclear

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

## Questions?

- Open an issue for questions
- Check existing issues and discussions
- Read the documentation thoroughly

Thank you for contributing! 🎉

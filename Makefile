.PHONY: help build start stop restart logs test clean create-repo list-repos shell

# Default target
help:
	@echo "Git Server Docker - Available Commands"
	@echo ""
	@echo "  make build        - Build the Docker image"
	@echo "  make start        - Start the git server (docker-compose)"
	@echo "  make stop         - Stop the git server"
	@echo "  make restart      - Restart the git server"
	@echo "  make logs         - Show container logs"
	@echo "  make test         - Run automated tests"
	@echo "  make clean        - Stop and remove containers, volumes, and test files"
	@echo "  make create-repo  - Create a new repository (use NAME=myrepo)"
	@echo "  make list-repos   - List all repositories"
	@echo "  make shell        - Open a shell in the container"
	@echo "  make validate     - Validate configuration files"
	@echo ""

# Build the Docker image
build:
	@echo "Building git-server image..."
	docker build -t git-server:latest .
	@echo "✓ Build complete"

# Start the server
start:
	@echo "Starting git server..."
	@if [ ! -f authorized_keys ]; then \
		echo "Warning: authorized_keys not found!"; \
		echo "Creating example file - add your SSH keys before connecting"; \
		cp authorized_keys.example authorized_keys; \
	fi
	docker-compose up -d
	@echo "✓ Git server started on port 2222"
	@echo ""
	@echo "To create a repository: make create-repo NAME=myproject"
	@echo "To view logs: make logs"

# Stop the server
stop:
	@echo "Stopping git server..."
	docker-compose down
	@echo "✓ Git server stopped"

# Restart the server
restart: stop start

# Show logs
logs:
	docker-compose logs -f git-server

# Run automated tests
test:
	@echo "Running automated tests..."
	@./test-setup.sh

# Create a new repository
create-repo:
	@if [ -z "$(NAME)" ]; then \
		echo "Error: Repository name required"; \
		echo "Usage: make create-repo NAME=myproject"; \
		exit 1; \
	fi
	@echo "Creating repository: $(NAME)"
	@docker-compose exec git-server /usr/local/bin/init-repo.sh $(NAME)
	@echo ""
	@echo "Clone with:"
	@echo "  git clone ssh://git@localhost:2222/srv/git/$(NAME).git"

# List all repositories
list-repos:
	@echo "Repositories:"
	@docker-compose exec git-server ls -lh /srv/git

# Open shell in container
shell:
	@docker-compose exec git-server /bin/bash

# Validate configuration files
validate:
	@echo "Validating Dockerfile..."
	@docker build --check .
	@echo "✓ Dockerfile is valid"
	@echo ""
	@echo "Validating docker-compose.yml..."
	@docker-compose config > /dev/null
	@echo "✓ docker-compose.yml is valid"
	@echo ""
	@echo "Validating shell scripts..."
	@bash -n docker-entrypoint.sh
	@bash -n init-repo.sh
	@bash -n test-setup.sh
	@echo "✓ Shell scripts are valid"

# Clean up everything
clean:
	@echo "Cleaning up..."
	@docker-compose down -v 2>/dev/null || true
	@docker rm -f git-server-test 2>/dev/null || true
	@rm -rf test_key test_key.pub test-repo authorized_keys 2>/dev/null || true
	@docker volume rm $$(docker volume ls -q | grep git) 2>/dev/null || true
	@echo "✓ Cleanup complete"

# Quick setup for first-time users
quickstart:
	@echo "Git Server Quick Setup"
	@echo "======================"
	@echo ""
	@if [ ! -f ~/.ssh/id_rsa.pub ] && [ ! -f ~/.ssh/id_ed25519.pub ]; then \
		echo "No SSH key found. Generating one..."; \
		ssh-keygen -t ed25519 -f ~/.ssh/git_server_key -N "" -C "git@server"; \
		cp ~/.ssh/git_server_key.pub authorized_keys; \
	else \
		echo "SSH key found. Copying to authorized_keys..."; \
		if [ -f ~/.ssh/id_ed25519.pub ]; then \
			cp ~/.ssh/id_ed25519.pub authorized_keys; \
		else \
			cp ~/.ssh/id_rsa.pub authorized_keys; \
		fi; \
	fi
	@echo "✓ SSH keys configured"
	@echo ""
	@make build
	@echo ""
	@make start
	@echo ""
	@echo "✓ Git server is ready!"
	@echo ""
	@echo "Next steps:"
	@echo "  1. Create a repository: make create-repo NAME=myproject"
	@echo "  2. Clone it: git clone ssh://git@localhost:2222/srv/git/myproject.git"

# Development helpers
dev-build:
	docker build --no-cache -t git-server:dev .

dev-shell:
	docker run --rm -it git-server:dev /bin/bash

# Check container status
status:
	@echo "Git Server Status:"
	@echo "=================="
	@if docker ps | grep -q git-server; then \
		echo "✓ Container is running"; \
		echo ""; \
		docker ps --filter name=git-server --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"; \
	else \
		echo "✗ Container is not running"; \
		echo ""; \
		echo "Start with: make start"; \
	fi

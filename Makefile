SHELL:=$(shell which bash)
GIT_ROOT=$(shell git rev-parse --show-toplevel)
CURL=$(shell which curl)
TOOLS_HOME=$(GIT_ROOT)/.tools
TOOLS_BIN=$(TOOLS_HOME)/bin
VIRTUAL_ENV=$(TOOLS_HOME)/venv
GIT_PRE_COMMIT=$(GIT_ROOT)/.git/hooks/pre-commit
DOCKER_TAG ?= latest

export VIRTUAL_ENV

ifndef VERBOSE
.SILENT:
endif

.PHONY: help
help:
	@grep -hE '^[%0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: clean
clean:
	rm -rf $(TOOLS_HOME)

$(CURL):
	$(error 'curl' could not be found on the PATH. Please install curl)

UV_ARCH=$(shell uname -m | sed 's/arm64/aarch64-apple-darwin/g' | sed 's/x86_64/x86_64-unknown-linux-gnu/g')
UV_VERSION=0.9.22
UV_ROOT=$(TOOLS_HOME)/uv-$(UV_VERSION)
UV=$(UV_ROOT)/uv-$(UV_ARCH)/uv
$(UV): | $(CURL)
	echo "Installing uv $(UV_VERSION)"
	mkdir -p $(UV_ROOT)
	$(CURL) -Ls https://github.com/astral-sh/uv/releases/download/$(UV_VERSION)/uv-$(UV_ARCH).tar.gz | tar -xz -C $(UV_ROOT)

PYTHON_DEPS=$(VIRTUAL_ENV)/.python-deps-installed
$(PYTHON_DEPS): | $(UV)
	echo "Installing Python Environment with uv"
	$(UV) venv --clear $(VIRTUAL_ENV)
	$(UV) pip install 'pre-commit>=3.0.0'
	touch $@

deps: $(PYTHON_DEPS)

PRE_COMMIT=$(VIRTUAL_ENV)/bin/pre-commit
$(PRE_COMMIT): | $(PYTHON_DEPS)

$(GIT_PRE_COMMIT): $(PRE_COMMIT)
	$(PRE_COMMIT) install

LIMA_VERSION=2.0.3
LIMA_ROOT=$(TOOLS_HOME)/lima-$(LIMA_VERSION)
LIMA=$(LIMA_ROOT)/bin/limactl
LIMA_ARCH=$(shell uname -m)
LIMA_PLATFORM=$(shell uname)
$(LIMA):
	echo "Installing Lima $LIMA_VERSION"
	mkdir -p $(LIMA_ROOT)
	$(CURL) -Ls https://github.com/lima-vm/lima/releases/download/v$(LIMA_VERSION)/lima-$(LIMA_VERSION)-$(LIMA_PLATFORM)-$(LIMA_ARCH).tar.gz | tar -xz -C $(LIMA_ROOT)

COLIMA_ARCH=$(shell uname -m)
COLIMA_PLATFORM=$(shell uname)
COLIMA_VERSION=v0.8.1
COLIMA_ROOT=$(TOOLS_HOME)/colima-$(COLIMA_VERSION)
COLIMA=$(COLIMA_ROOT)/colima-$(COLIMA_PLATFORM)-$(COLIMA_ARCH)
$(COLIMA): | $(LIMA)
	echo "Installing Colima"
	mkdir -p $(COLIMA_ROOT)
	$(CURL) -Ls https://github.com/abiosoft/colima/releases/download/$(COLIMA_VERSION)/colima-$(COLIMA_PLATFORM)-$(COLIMA_ARCH) -o $(COLIMA)
	chmod +x $(COLIMA)

DOCKER_VERSION=20.10.10
DOCKER_ROOT=$(TOOLS_HOME)/docker-$(DOCKER_VERSION)
DOCKER_PLATFORM=$(shell uname | sed 's/Darwin/mac/g' | sed 's/Linux/linux/g')
DOCKER=$(DOCKER_ROOT)/docker/docker
DOCKER_ARCH=$(shell uname -m | sed 's/arm64/aarch64/g')
DOCKER_SOURCE=https://download.docker.com/$(DOCKER_PLATFORM)/static/stable/$(DOCKER_ARCH)/docker-$(DOCKER_VERSION).tgz
$(DOCKER):
	echo "Installing Docker from $(DOCKER_SOURCE)"
	mkdir -p $(DOCKER_ROOT)
	$(CURL) -Ls $(DOCKER_SOURCE) | tar -xz -C $(DOCKER_ROOT)

DOCKER_DAEMON=$(shell [ -S /var/run/docker.sock ] && echo /var/run/docker.sock || echo $(HOME)/.colima/docker.sock)
$(DOCKER_DAEMON):
	make $(COLIMA)
	echo "Starting Docker Daemon with socket $(DOCKER_DAEMON)"
	$(COLIMA) start --cpu 2 --memory 4 --disk 50

export PATH := $(TOOLS_HOME)/bin:$(LIMA_ROOT)/bin:$(DOCKER_ROOT)/docker:$(VENV)/bin:$(PATH)

docker-daemon: $(DOCKER)
	$(DOCKER) ps > /dev/null || make docker-daemon-clean
	make $(DOCKER_DAEMON)

docker-daemon-clean: | $(COLIMA)
	$(COLIMA) stop
	$(COLIMA) delete
	rm -rf $(HOME)/.colima

.PHONY: hooks
hooks: $(GIT_PRE_COMMIT) ## Install pre-commit hooks

.PHONY: pre-commit
pre-commit: hooks ## Reformat code, stage changes, and run pre-commit checks
	$(PRE_COMMIT)

build: hooks $(DOCKER) $(DOCKER_DAEMON)
	echo "Building agent container"
	$(DOCKER) build -t legit-server:$(DOCKER_TAG) -f container/Dockerfile .

# Build the Docker image
build: $(DOCKER)
	echo "Building legit-server image..."
	$(DOCKER) build -t legit-server:latest .
	echo "✓ Build complete"

# Start the server
start: $(DOCKER)
	echo "Starting git server..."
	if [ ! -f authorized_keys ]; then \
		echo "Warning: authorized_keys not found!"; \
		echo "Creating example file - add your SSH keys before connecting"; \
		cp authorized_keys.example authorized_keys; \
	fi
	$(DOCKER) run -d \
		--name legit-server \
		-p 2222:22 \
		-v $$(pwd)/authorized_keys:/home/git/.ssh/authorized_keys:ro \
		-v git-repos:/srv/git \
		-v ssh-host-keys:/etc/ssh/ssh_host_keys \
		-e REPOSITORIES_HOME_LINK=true \
		legit-server:latest
	echo "✓ Git server started on port 2222"
	echo ""
	echo "To create a repository: make create-repo NAME=myproject"
	echo "To view logs: make logs"

# Stop the server
stop:
	echo "Stopping git server..."
	docker stop legit-server 2>/dev/null || true
	docker rm legit-server 2>/dev/null || true
	echo "✓ Git server stopped"

# Restart the server
restart: stop start

# Show logs
logs: $(DOCKER)
	$(DOCKER) logs -f legit-server

# Run automated tests
test:
	echo "Running automated tests..."
	./test-setup.sh

# Create a new repository
create-repo:
	if [ -z "$(NAME)" ]; then \
		echo "Error: Repository name required"; \
		echo "Usage: make create-repo NAME=myproject"; \
		exit 1; \
	fi
	echo "Creating repository: $(NAME)"
	$(DOCKER) exec legit-server /usr/local/bin/init-repo.sh $(NAME)
	echo ""
	echo "Clone with:"
	echo "  git clone ssh://git@localhost:2222/srv/git/$(NAME).git"

# List all repositories
list-repos:
	echo "Repositories:"
	$(DOCKER) exec legit-server ls -lh /srv/git

# Open shell in container
shell:
	@docker exec -it legit-server /bin/bash

# Validate configuration files
validate: $(DOCKER)
	echo "Validating Dockerfile..."
	$(DOCKER) build --check .
	echo "✓ Dockerfile is valid"
	echo ""
	echo "Validating shell scripts..."
	# TODO replace this with shellcheck
	bash -n docker-entrypoint.sh
	bash -n init-repo.sh
	bash -n test-setup.sh
	echo "✓ Shell scripts are valid"

# Clean up everything
clean: $(DOCKER)
	echo "Cleaning up..."
	$(DOCKER) stop legit-server 2>/dev/null || true
	$(DOCKER) rm legit-server 2>/dev/null || true
	$(DOCKER) rm -f legit-server-test 2>/dev/null || true
	rm -rf test_key test_key.pub test-repo authorized_keys 2>/dev/null || true
	$(DOCKER) volume rm git-repos ssh-host-keys 2>/dev/null || true
	$(DOCKER) volume rm $$(docker volume ls -q | grep git) 2>/dev/null || true
	echo "✓ Cleanup complete"

# Development helpers
dev-build:
	docker build --no-cache -t legit-server:dev .

shell: build
	$(DOCKER) run --rm -it legit-server:dev /bin/bash
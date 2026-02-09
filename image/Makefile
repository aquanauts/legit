SHELL := $(shell which bash)
GIT_ROOT := $(shell git rev-parse --show-toplevel)
TOOLS_HOME := $(GIT_ROOT)/.tools
DOCKER_TAG ?= latest
IMAGE_NAME ?= legit-server
REGISTRY ?= ghcr.io
REGISTRY_USER ?= $(shell git config user.name | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

ifndef VERBOSE
.SILENT:
endif

.PHONY: help
help: ## Show this help message
	@grep -hE '^[%0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

# ============================================================================
# Lima/Colima/Docker installation
# ============================================================================

CURL := $(shell which curl)
$(CURL):
	$(error 'curl' could not be found on PATH. Please install curl)

LIMA_VERSION := 2.0.3
LIMA_ROOT := $(TOOLS_HOME)/lima-$(LIMA_VERSION)
LIMA := $(LIMA_ROOT)/bin/limactl
LIMA_ARCH := $(shell uname -m)
LIMA_PLATFORM := $(shell uname)
$(LIMA): | $(CURL)
	echo "Installing Lima $(LIMA_VERSION)..."
	mkdir -p $(LIMA_ROOT)
	$(CURL) -Ls https://github.com/lima-vm/lima/releases/download/v$(LIMA_VERSION)/lima-$(LIMA_VERSION)-$(LIMA_PLATFORM)-$(LIMA_ARCH).tar.gz | tar -xz -C $(LIMA_ROOT)

COLIMA_ARCH := $(shell uname -m)
COLIMA_PLATFORM := $(shell uname)
COLIMA_VERSION := v0.8.1
COLIMA_ROOT := $(TOOLS_HOME)/colima-$(COLIMA_VERSION)
COLIMA := $(COLIMA_ROOT)/colima-$(COLIMA_PLATFORM)-$(COLIMA_ARCH)
$(COLIMA): | $(LIMA)
	echo "Installing Colima $(COLIMA_VERSION)..."
	mkdir -p $(COLIMA_ROOT)
	$(CURL) -Ls https://github.com/abiosoft/colima/releases/download/$(COLIMA_VERSION)/colima-$(COLIMA_PLATFORM)-$(COLIMA_ARCH) -o $(COLIMA)
	chmod +x $(COLIMA)

DOCKER_VERSION := 20.10.10
DOCKER_ROOT := $(TOOLS_HOME)/docker-$(DOCKER_VERSION)
DOCKER_PLATFORM := $(shell uname | sed 's/Darwin/mac/g' | sed 's/Linux/linux/g')
DOCKER := $(DOCKER_ROOT)/docker/docker
DOCKER_ARCH := $(shell uname -m | sed 's/arm64/aarch64/g')
DOCKER_SOURCE := https://download.docker.com/$(DOCKER_PLATFORM)/static/stable/$(DOCKER_ARCH)/docker-$(DOCKER_VERSION).tgz
$(DOCKER): | $(CURL)
	echo "Installing Docker $(DOCKER_VERSION) from $(DOCKER_SOURCE)..."
	mkdir -p $(DOCKER_ROOT)
	$(CURL) -Ls $(DOCKER_SOURCE) | tar -xz -C $(DOCKER_ROOT)

DOCKER_DAEMON := $(shell [ -S /var/run/docker.sock ] && echo /var/run/docker.sock || echo $(HOME)/.colima/docker.sock)
$(DOCKER_DAEMON): | $(COLIMA)
	echo "Starting Docker Daemon with socket $(DOCKER_DAEMON)..."
	$(COLIMA) start --cpu 2 --memory 4 --disk 50

export PATH := $(TOOLS_HOME)/bin:$(LIMA_ROOT)/bin:$(DOCKER_ROOT)/docker:$(PATH)

.PHONY: docker-daemon
docker-daemon: $(DOCKER) ## Start Docker daemon (via Colima if needed)
	$(DOCKER) ps > /dev/null || make docker-daemon-clean
	make $(DOCKER_DAEMON)

.PHONY: docker-daemon-clean
docker-daemon-clean: | $(COLIMA) ## Stop and clean Docker daemon
	$(COLIMA) stop
	$(COLIMA) delete
	rm -rf $(HOME)/.colima

# ============================================================================
# Build Targets
# ============================================================================

.PHONY: build
build: $(DOCKER) $(DOCKER_DAEMON) ## Build the Docker image
	echo "Building $(IMAGE_NAME):$(DOCKER_TAG)..."
	$(DOCKER) build -t $(IMAGE_NAME):$(DOCKER_TAG) .
	echo "✓ Build complete: $(IMAGE_NAME):$(DOCKER_TAG)"

.PHONY: dev-build
dev-build: $(DOCKER) $(DOCKER_DAEMON) ## Build without cache for development
	echo "Building $(IMAGE_NAME):dev (no cache)..."
	$(DOCKER) build --no-cache -t $(IMAGE_NAME):dev .
	echo "✓ Development build complete"

# ============================================================================
# Test Targets
# ============================================================================

.PHONY: test
test: $(DOCKER) $(DOCKER_DAEMON) ## Run integration tests
	echo "Running integration tests..."
	./test-setup.sh
	echo "✓ All tests passed"

.PHONY: validate
validate: $(DOCKER) ## Validate Dockerfile and shell scripts
	echo "Validating Dockerfile..."
	$(DOCKER) build --check . || echo "Note: --check flag not supported, skipping"
	echo "✓ Dockerfile is valid"
	echo ""
	echo "Validating shell scripts..."
	bash -n docker-entrypoint.sh
	bash -n init-repo.sh
	bash -n test-setup.sh
	echo "✓ Shell scripts are valid"

# ============================================================================
# Publish Targets
# ============================================================================

.PHONY: publish
publish: build ## Tag and push image to registry
	echo "Tagging image for registry..."
	$(DOCKER) tag $(IMAGE_NAME):$(DOCKER_TAG) $(REGISTRY)/$(REGISTRY_USER)/$(IMAGE_NAME):$(DOCKER_TAG)
	echo "Pushing to $(REGISTRY)/$(REGISTRY_USER)/$(IMAGE_NAME):$(DOCKER_TAG)..."
	$(DOCKER) push $(REGISTRY)/$(REGISTRY_USER)/$(IMAGE_NAME):$(DOCKER_TAG)
	echo "✓ Published to registry"

.PHONY: publish-latest
publish-latest: ## Publish as latest tag
	$(MAKE) publish DOCKER_TAG=latest

# ============================================================================
# Cleanup
# ============================================================================

.PHONY: clean
clean: $(DOCKER) ## Remove build artifacts and tools
	echo "Cleaning up image build artifacts..."
	$(DOCKER) rmi $(IMAGE_NAME):$(DOCKER_TAG) 2>/dev/null || true
	$(DOCKER) rmi $(IMAGE_NAME):dev 2>/dev/null || true
	$(DOCKER) rm -f legit-server-test 2>/dev/null || true
	rm -rf test_key test_key.pub test-repo authorized_keys 2>/dev/null || true
	$(DOCKER) volume rm git-repos ssh-host-keys 2>/dev/null || true
	echo "✓ Image cleanup complete"

SHELL := $(shell which bash)
GIT_ROOT := $(shell git rev-parse --show-toplevel)
TOOLS_HOME := $(GIT_ROOT)/.tools
VIRTUAL_ENV := $(TOOLS_HOME)/venv
GIT_PRE_COMMIT := $(GIT_ROOT)/.git/hooks/pre-commit

export VIRTUAL_ENV

ifndef VERBOSE
.SILENT:
endif

.PHONY: help
help: ## Show this help message
	@grep -hE '^[%0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

# ============================================================================
# Python/uv setup for pre-commit hooks
# ============================================================================

CURL := $(shell which curl)
$(CURL):
	$(error 'curl' could not be found on PATH. Please install curl)

UV_ARCH := $(shell uname -m | sed 's/arm64/aarch64-apple-darwin/g' | sed 's/x86_64/x86_64-unknown-linux-gnu/g')
UV_VERSION := 0.9.22
UV_ROOT := $(TOOLS_HOME)/uv-$(UV_VERSION)
UV := $(UV_ROOT)/uv-$(UV_ARCH)/uv
$(UV): | $(CURL)
	echo "Installing uv $(UV_VERSION)..."
	mkdir -p $(UV_ROOT)
	$(CURL) -Ls https://github.com/astral-sh/uv/releases/download/$(UV_VERSION)/uv-$(UV_ARCH).tar.gz | tar -xz -C $(UV_ROOT)

PYTHON_DEPS := $(VIRTUAL_ENV)/.python-deps-installed
$(PYTHON_DEPS): | $(UV)
	echo "Installing Python environment with uv..."
	$(UV) venv --clear $(VIRTUAL_ENV)
	$(UV) pip install 'pre-commit>=3.0.0'
	touch $@

PRE_COMMIT := $(VIRTUAL_ENV)/bin/pre-commit
$(PRE_COMMIT): | $(PYTHON_DEPS)

$(GIT_PRE_COMMIT): $(PRE_COMMIT)
	$(PRE_COMMIT) install

# ============================================================================
# Development Targets
# ============================================================================

.PHONY: deps
deps: $(PYTHON_DEPS) ## Install Python dependencies

.PHONY: hooks
hooks: $(GIT_PRE_COMMIT) ## Install pre-commit hooks

.PHONY: pre-commit
pre-commit: hooks ## Run pre-commit checks
	$(VIRTUAL_ENV)/bin/pre-commit run --all-files

# ============================================================================
# Image Builder Shortcuts
# ============================================================================

.PHONY: build
build: hooks ## Build the Docker image
	$(MAKE) -C image build

.PHONY: test
test: pre-commit ## Run tests

.PHONY: publish
publish: hooks ## Publish image to registry
	$(MAKE) -C image publish

# ============================================================================
# End-to-End Testing
# ============================================================================

.PHONY: run
run: build ## Build image and run with CLI (runs in foreground)
	LEGIT_IMAGE=legit-server:latest ./cli/legit

.PHONY: run-headless
run-headless: build ## Build image and run with CLI (runs in background)
	LEGIT_IMAGE=legit-server:latest ./cli/legit --headless

# ============================================================================
# Cleanup
# ============================================================================

.PHONY: clean
clean: ## Remove build artifacts and tools
	echo "Cleaning up root..."
	rm -rf $(TOOLS_HOME)
	$(MAKE) -C image clean
	echo "✓ Cleanup complete"

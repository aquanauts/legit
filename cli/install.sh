#!/bin/bash
#
# legit installer - Install the legit CLI tool
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/USERNAME/legit/main/cli/install.sh | bash
#
# Or with custom installation directory:
#   curl -fsSL https://raw.githubusercontent.com/USERNAME/legit/main/cli/install.sh | bash -s -- /custom/path
#

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

REPO_URL="https://raw.githubusercontent.com/USERNAME/legit/main"
DEFAULT_INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="${HOME}/.config/legit"

# ============================================================================
# Colors and Formatting
# ============================================================================

if [[ -t 1 ]]; then
    BOLD="\033[1m"
    GREEN="\033[32m"
    YELLOW="\033[33m"
    RESET="\033[0m"
else
    BOLD=""
    GREEN=""
    YELLOW=""
    RESET=""
fi

# ============================================================================
# Helper Functions
# ============================================================================

log() {
    echo -e "$*"
}

log_success() {
    log "${GREEN}✓${RESET} $*"
}

log_warn() {
    log "${YELLOW}⚠${RESET} $*"
}

die() {
    echo "Error: $*" >&2
    exit 1
}

# ============================================================================
# Installation
# ============================================================================

install_legit() {
    local install_dir="${1:-$DEFAULT_INSTALL_DIR}"
    local install_path="${install_dir}/legit"

    log ""
    log "${BOLD}Installing legit CLI...${RESET}"
    log ""

    # Check if curl is available
    if ! command -v curl &> /dev/null; then
        die "curl is required but not installed. Please install curl and try again."
    fi

    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        log_warn "Docker is not installed."
        log "  legit requires Docker to run."
        log "  Install Docker from: https://docs.docker.com/get-docker/"
        log ""
    fi

    # Determine if we need sudo
    local use_sudo=""
    if [[ ! -w "$install_dir" ]]; then
        if command -v sudo &> /dev/null; then
            log "Installing to $install_dir (requires sudo)"
            use_sudo="sudo"
        else
            die "Cannot write to $install_dir and sudo is not available. Try: $0 \$HOME/bin"
        fi
    fi

    # Create install directory if it doesn't exist
    if [[ ! -d "$install_dir" ]]; then
        log "Creating directory: $install_dir"
        $use_sudo mkdir -p "$install_dir"
    fi

    # Download the legit script
    log "Downloading legit CLI..."
    if ! curl -fsSL "${REPO_URL}/cli/legit" -o "/tmp/legit"; then
        die "Failed to download legit CLI from ${REPO_URL}/cli/legit"
    fi

    # Install the script
    log "Installing to $install_path..."
    $use_sudo mv /tmp/legit "$install_path"
    $use_sudo chmod +x "$install_path"

    log_success "legit CLI installed to $install_path"

    # Create config directory
    if [[ ! -d "$CONFIG_DIR" ]]; then
        mkdir -p "$CONFIG_DIR"
        log_success "Created config directory: $CONFIG_DIR"
    fi

    # Check if install_dir is in PATH
    if [[ ":$PATH:" != *":$install_dir:"* ]]; then
        log_warn "$install_dir is not in your PATH"
        log "  Add it to your PATH by adding this to your ~/.bashrc or ~/.zshrc:"
        log "  ${BOLD}export PATH=\"\$PATH:$install_dir\"${RESET}"
        log ""
    fi

    # Print next steps
    log ""
    log "${BOLD}Installation complete!${RESET}"
    log ""
    log "Next steps:"
    log "  1. Start the Git server:"
    log "     ${BOLD}legit start${RESET}"
    log ""
    log "  2. Create a repository:"
    log "     ${BOLD}legit create-repo myproject${RESET}"
    log ""
    log "  3. Clone and use:"
    log "     ${BOLD}git clone ssh://git@localhost:2222/srv/git/myproject.git${RESET}"
    log ""
    log "For more help:"
    log "  ${BOLD}legit help${RESET}"
    log ""
}

# ============================================================================
# Main
# ============================================================================

main() {
    local install_dir="${1:-$DEFAULT_INSTALL_DIR}"

    # Expand ~ to $HOME
    install_dir="${install_dir/#\~/$HOME}"

    install_legit "$install_dir"
}

main "$@"

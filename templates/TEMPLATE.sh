#!/usr/bin/env bash
#
# Installation script template
# Copy this file and customize the marked sections
#
# ============================================================================
# CUSTOMIZE THESE VALUES
# ============================================================================
# Tool name and description
readonly TOOL_NAME="example-tool"
readonly TOOL_DISPLAY_NAME="Example Tool"
readonly TOOL_DESCRIPTION="Brief description of what this tool does"
readonly TOOL_SOURCE_URL="https://example.com/docs"

# Supported OS (space-separated: "debian ubuntu")
readonly SUPPORTED_OS="debian ubuntu"

# Required system commands (checked before installation)
readonly REQUIRED_DEPS=("curl" "wget" "sudo")

# APT packages needed for installation (empty string if none)
readonly APT_DEPENDENCIES="ca-certificates curl"

# How to check if already installed (bash command that returns 0 if installed)
check_if_installed() {
    command -v example-tool &> /dev/null
}

# How to verify installation succeeded (bash command that returns 0 if working)
verify_installation_works() {
    example-tool --version &> /dev/null
}

# Cleanup commands (run on exit, even if script fails)
cleanup_on_exit() {
    # Example: rm -f /tmp/example-tool.deb
    :  # No cleanup needed
}

# ============================================================================
# MAIN INSTALLATION FUNCTION - CUSTOMIZE THIS
# ============================================================================
install_tool() {
    log_info "Starting installation..."

    # Example: Download and install
    # wget -O /tmp/tool.deb https://example.com/tool.deb
    # sudo dpkg -i /tmp/tool.deb
    # sudo apt-get install -f -y

    # Example: Add repository and install
    # sudo curl -fsSL https://example.com/key.gpg -o /etc/apt/keyrings/tool.asc
    # echo "deb [signed-by=/etc/apt/keyrings/tool.asc] https://example.com/repo stable main" | sudo tee /etc/apt/sources.list.d/tool.list
    # sudo apt-get update
    # sudo apt-get install -y tool-package

    # Example: Binary download
    # curl -L https://example.com/binary -o /tmp/tool
    # chmod +x /tmp/tool
    # sudo mv /tmp/tool /usr/local/bin/tool

    # TODO: Add your installation commands here
    log_error "Installation not implemented - customize install_tool() function"
    return 1
}

# ============================================================================
# STANDARD FRAMEWORK - DO NOT MODIFY BELOW THIS LINE
# ============================================================================
set -euo pipefail
IFS=$'\n\t'

readonly SCRIPT_VERSION="1.0.0"
readonly LOG_FILE="${LOG_FILE:-/tmp/${TOOL_NAME}-install.log}"

# Logging functions
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    echo "[${timestamp}] [${level}] ${message}" | tee -a "${LOG_FILE}"
}

log_info() { log "INFO" "$@"; }
log_warn() { log "WARN" "$@"; }
log_error() { log "ERROR" "$@"; }
log_success() { log "SUCCESS" "$@"; }

error_exit() {
    log_error "$@"
    exit 1
}

# Cleanup handler
cleanup() {
    local exit_code=$?
    if [[ ${exit_code} -ne 0 ]]; then
        log_error "Installation failed with exit code ${exit_code}"
        log_info "Check log file: ${LOG_FILE}"
    fi
    cleanup_on_exit
}

trap cleanup EXIT
trap 'error_exit "Script interrupted"' INT TERM

# OS Detection
detect_os() {
    if [[ -f /etc/os-release ]]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        OS="${ID}"
        OS_VERSION="${VERSION_ID}"
        OS_CODENAME="${VERSION_CODENAME:-}"
    else
        error_exit "Cannot detect OS. /etc/os-release not found."
    fi
    log_info "Detected OS: ${OS} ${OS_VERSION} (${OS_CODENAME})"
}

check_supported_os() {
    if [[ ! " ${SUPPORTED_OS} " =~ " ${OS} " ]]; then
        error_exit "Unsupported OS: ${OS}. Supported: ${SUPPORTED_OS}"
    fi
}

# Dependency checking
check_command() {
    local cmd="$1"
    if ! command -v "${cmd}" &> /dev/null; then
        log_warn "Required command not found: ${cmd}"
        return 1
    fi
    return 0
}

check_dependencies() {
    local missing=()
    for dep in "${REQUIRED_DEPS[@]}"; do
        if ! check_command "${dep}"; then
            missing+=("${dep}")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing dependencies: ${missing[*]}"
        return 1
    fi
    log_info "All dependencies satisfied"
    return 0
}

install_dependencies() {
    if [[ -z "${APT_DEPENDENCIES}" ]]; then
        return 0
    fi
    log_info "Installing dependencies: ${APT_DEPENDENCIES}"
    sudo apt-get update -qq || error_exit "apt-get update failed"
    # shellcheck disable=SC2086
    sudo apt-get install -y ${APT_DEPENDENCIES} || error_exit "Failed to install dependencies"
}

# Usage
usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Install ${TOOL_DISPLAY_NAME} on supported Linux distributions.

OPTIONS:
    -h, --help          Show this help message
    -v, --version       Show script version
    -f, --force         Force reinstall even if already installed
    --no-verify         Skip installation verification
    --dry-run           Show what would be done without executing

DESCRIPTION:
    ${TOOL_DESCRIPTION}

SUPPORTED OS: ${SUPPORTED_OS}
SOURCE: ${TOOL_SOURCE_URL}
VERSION: ${SCRIPT_VERSION}
EOF
}

# Main execution
main() {
    local force_install=false
    local skip_verify=false
    local dry_run=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                usage
                exit 0
                ;;
            -v|--version)
                echo "${SCRIPT_VERSION}"
                exit 0
                ;;
            -f|--force)
                force_install=true
                shift
                ;;
            --no-verify)
                skip_verify=true
                shift
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            *)
                error_exit "Unknown option: $1. Use --help for usage."
                ;;
        esac
    done

    log_info "Starting ${TOOL_DISPLAY_NAME} installation (version ${SCRIPT_VERSION})"

    # System checks
    detect_os
    check_supported_os

    # Check if already installed
    if [[ "${force_install}" == "false" ]] && check_if_installed; then
        log_success "${TOOL_DISPLAY_NAME} is already installed"
        exit 0
    fi

    # Dependency checks
    check_dependencies || install_dependencies

    if [[ "${dry_run}" == "true" ]]; then
        log_info "Dry run mode - exiting before installation"
        exit 0
    fi

    # Execute installation
    install_tool

    # Verify
    if [[ "${skip_verify}" == "false" ]]; then
        log_info "Verifying installation..."
        if verify_installation_works; then
            log_success "Installation verified successfully"
        else
            log_error "Installation verification failed"
            exit 1
        fi
    fi

    log_success "${TOOL_DISPLAY_NAME} installation completed successfully!"
}

main "$@"

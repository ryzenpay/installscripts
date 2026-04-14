#!/usr/bin/env bash
#
# Installation script for: {{TOOL_NAME}}
# Description: {{DESCRIPTION}}
# Source: {{SOURCE_URL}}
# Generated: {{GENERATED_DATE}}
#

set -euo pipefail
IFS=$'\n\t'

# ============================================================================
# CONFIGURATION
# ============================================================================
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly SCRIPT_VERSION="{{VERSION}}"
readonly TOOL_NAME="{{TOOL_NAME}}"
readonly LOG_FILE="${LOG_FILE:-/tmp/${TOOL_NAME}-install.log}"

# Tool-specific configuration
{{CONFIG_SECTION}}

# ============================================================================
# LOGGING & ERROR HANDLING
# ============================================================================
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

cleanup() {
    local exit_code=$?
    if [[ ${exit_code} -ne 0 ]]; then
        log_error "Installation failed with exit code ${exit_code}"
        log_info "Check log file: ${LOG_FILE}"
    fi
    {{CLEANUP_COMMANDS}}
}

trap cleanup EXIT
trap 'error_exit "Script interrupted"' INT TERM

# ============================================================================
# SYSTEM DETECTION
# ============================================================================
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
    local supported_os="{{SUPPORTED_OS}}"
    if [[ ! " ${supported_os} " =~ " ${OS} " ]]; then
        error_exit "Unsupported OS: ${OS}. Supported: ${supported_os}"
    fi
}

# ============================================================================
# DEPENDENCY CHECKING
# ============================================================================
check_command() {
    local cmd="$1"
    if ! command -v "${cmd}" &> /dev/null; then
        log_warn "Required command not found: ${cmd}"
        return 1
    fi
    return 0
}

check_dependencies() {
    local deps=({{REQUIRED_DEPS}})
    local missing=()

    for dep in "${deps[@]}"; do
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
    local deps="{{APT_DEPENDENCIES}}"
    if [[ -z "${deps}" ]]; then
        return 0
    fi

    log_info "Installing dependencies: ${deps}"
    sudo apt-get update -qq || error_exit "apt-get update failed"
    # shellcheck disable=SC2086
    sudo apt-get install -y ${deps} || error_exit "Failed to install dependencies"
}

# ============================================================================
# IDEMPOTENCY CHECKS
# ============================================================================
is_already_installed() {
    {{INSTALLED_CHECK}}
}

# ============================================================================
# INSTALLATION FUNCTIONS
# ============================================================================
{{INSTALLATION_FUNCTIONS}}

# ============================================================================
# VERIFICATION
# ============================================================================
verify_installation() {
    log_info "Verifying installation..."
    {{VERIFY_COMMANDS}}
}

# ============================================================================
# USAGE
# ============================================================================
usage() {
    cat <<EOF
Usage: ${SCRIPT_NAME} [OPTIONS]

Install ${TOOL_NAME} on supported Linux distributions.

OPTIONS:
    -h, --help          Show this help message
    -v, --version       Show script version
    -f, --force         Force reinstall even if already installed
    --no-verify         Skip installation verification
    --dry-run           Show what would be done without executing

EXAMPLES:
    # Standard installation
    curl -sfL http://your-server/{{TOOL_NAME_NORMALIZED}} | sh

    # Local execution
    bash ${SCRIPT_NAME}

    # Force reinstall
    bash ${SCRIPT_NAME} --force

SUPPORTED OS: {{SUPPORTED_OS}}
SOURCE: {{SOURCE_URL}}
VERSION: ${SCRIPT_VERSION}
EOF
}

# ============================================================================
# MAIN
# ============================================================================
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

    log_info "Starting ${TOOL_NAME} installation (version ${SCRIPT_VERSION})"

    # System checks
    detect_os
    check_supported_os

    # Check if already installed
    if [[ "${force_install}" == "false" ]] && is_already_installed; then
        log_success "${TOOL_NAME} is already installed"
        exit 0
    fi

    # Dependency checks
    check_dependencies || install_dependencies

    if [[ "${dry_run}" == "true" ]]; then
        log_info "Dry run mode - exiting before installation"
        exit 0
    fi

    # Execute installation
    install_{{TOOL_NAME_NORMALIZED}}

    # Verify
    if [[ "${skip_verify}" == "false" ]]; then
        verify_installation
    fi

    log_success "${TOOL_NAME} installation completed successfully!"
}

main "$@"

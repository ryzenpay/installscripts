#!/usr/bin/env bash
#
# Docker installation for Debian
# Source: https://docs.docker.com/engine/install/debian/
#
readonly TOOL_NAME="docker"
readonly TOOL_DISPLAY_NAME="Docker"
readonly TOOL_DESCRIPTION="Docker Engine container runtime"
readonly TOOL_SOURCE_URL="https://docs.docker.com/engine/install/debian/"
readonly SUPPORTED_OS="debian"
readonly REQUIRED_DEPS=("curl" "sudo")
readonly APT_DEPENDENCIES="ca-certificates curl"

check_if_installed() {
    command -v docker &> /dev/null
}

verify_installation_works() {
    docker --version &> /dev/null
}

cleanup_on_exit() {
    :  # No cleanup needed
}

install_tool() {
    log_info "Adding Docker GPG key..."
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    log_info "Adding Docker repository..."
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    log_info "Installing Docker packages..."
    sudo apt-get update -qq
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

# ============================================================================
# STANDARD FRAMEWORK
# ============================================================================
set -euo pipefail
IFS=$'\n\t'

readonly SCRIPT_VERSION="1.0.0"
readonly LOG_FILE="${LOG_FILE:-/tmp/${TOOL_NAME}-install.log}"

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
    cleanup_on_exit
}

trap cleanup EXIT
trap 'error_exit "Script interrupted"' INT TERM

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

main() {
    local force_install=false
    local skip_verify=false
    local dry_run=false

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

    detect_os
    check_supported_os

    if [[ "${force_install}" == "false" ]] && check_if_installed; then
        log_success "${TOOL_DISPLAY_NAME} is already installed"
        exit 0
    fi

    check_dependencies || install_dependencies

    if [[ "${dry_run}" == "true" ]]; then
        log_info "Dry run mode - exiting before installation"
        exit 0
    fi

    install_tool

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

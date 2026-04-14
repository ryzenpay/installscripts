#!/usr/bin/env bash
#
# Validate that all scripts follow the standard template
#

set -euo pipefail

readonly SCRIPTS_DIR="scripts"
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

# Required variables that must be defined in each script
REQUIRED_VARS=(
    "TOOL_NAME"
    "TOOL_DISPLAY_NAME"
    "TOOL_DESCRIPTION"
    "TOOL_SOURCE_URL"
    "SUPPORTED_OS"
    "REQUIRED_DEPS"
    "APT_DEPENDENCIES"
)

# Required functions that must be defined in each script
REQUIRED_FUNCTIONS=(
    "check_if_installed"
    "verify_installation_works"
    "cleanup_on_exit"
    "install_tool"
    "main"
)

log_info() {
    echo -e "${YELLOW}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $*"
}

log_error() {
    echo -e "${RED}[✗]${NC} $*"
}

validate_script() {
    local script_path="$1"
    local script_name
    script_name="$(basename "${script_path}")"
    local errors=0

    log_info "Validating ${script_path}..."

    # Check shebang
    if ! head -n 1 "${script_path}" | grep -q "^#!/usr/bin/env bash"; then
        log_error "  Missing or incorrect shebang (must be: #!/usr/bin/env bash)"
        ((errors++))
    fi

    # Check for required variables
    for var in "${REQUIRED_VARS[@]}"; do
        if ! grep -q "readonly ${var}=" "${script_path}"; then
            log_error "  Missing required variable: ${var}"
            ((errors++))
        fi
    done

    # Check for required functions
    for func in "${REQUIRED_FUNCTIONS[@]}"; do
        if ! grep -q "^${func}()" "${script_path}"; then
            log_error "  Missing required function: ${func}()"
            ((errors++))
        fi
    done

    # Check for 'set -euo pipefail'
    if ! grep -q "set -euo pipefail" "${script_path}"; then
        log_error "  Missing 'set -euo pipefail' for strict error handling"
        ((errors++))
    fi

    # Check for trap handlers
    if ! grep -q "trap cleanup EXIT" "${script_path}"; then
        log_error "  Missing 'trap cleanup EXIT' handler"
        ((errors++))
    fi

    # Check bash syntax
    if ! bash -n "${script_path}" 2>/dev/null; then
        log_error "  Bash syntax errors detected"
        ((errors++))
    fi

    if [[ ${errors} -eq 0 ]]; then
        log_success "${script_name} is valid"
        return 0
    else
        log_error "${script_name} has ${errors} error(s)"
        return 1
    fi
}

main() {
    log_info "Starting script validation..."
    echo ""

    local total=0
    local passed=0
    local failed=0
    local failed_scripts=()

    # Find all .sh files in scripts directory
    while IFS= read -r -d '' script; do
        total=$((total + 1))
        if validate_script "${script}"; then
            passed=$((passed + 1))
        else
            failed=$((failed + 1))
            failed_scripts+=("${script}")
        fi
        echo ""
    done < <(find "${SCRIPTS_DIR}" -name "*.sh" -type f -print0)

    # Print summary
    echo "========================================="
    echo "Validation Summary"
    echo "========================================="
    echo "Total:  ${total}"
    echo -e "Passed: ${GREEN}${passed}${NC}"
    echo -e "Failed: ${RED}${failed}${NC}"
    echo ""

    if [[ ${failed} -gt 0 ]]; then
        echo "Failed scripts:"
        for script in "${failed_scripts[@]}"; do
            echo "  - ${script}"
        done
        echo ""
        exit 1
    else
        log_success "All scripts are valid!"
        exit 0
    fi
}

main "$@"

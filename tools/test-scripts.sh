#!/usr/bin/env bash
#
# Test installation scripts in Docker containers
#

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"
readonly SCRIPTS_DIR="${PROJECT_ROOT}/scripts"
readonly TEST_RESULTS_DIR="${PROJECT_ROOT}/test-results"

# Test configurations
DISTRIBUTIONS=("debian:12" "ubuntu:22.04" "ubuntu:24.04")

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

log_info() {
    echo -e "${YELLOW}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

test_script() {
    local script_path="$1"
    local distro="$2"
    local script_name
    script_name="$(basename "${script_path}")"
    local test_name="${script_name%.sh}_${distro//:/}"

    log_info "Testing ${script_name} on ${distro}..."

    # Create test container
    local container_id
    container_id=$(docker run -d "${distro}" sleep 3600 2>/dev/null) || {
        log_error "Failed to create container for ${distro}"
        return 1
    }

    # Copy script into container
    docker cp "${script_path}" "${container_id}:/tmp/install.sh" 2>/dev/null || {
        log_error "Failed to copy script to container"
        docker rm -f "${container_id}" > /dev/null 2>&1
        return 1
    }

    # Run installation (dry-run mode)
    local exit_code=0
    docker exec "${container_id}" bash /tmp/install.sh --dry-run > "${TEST_RESULTS_DIR}/${test_name}.log" 2>&1 || exit_code=$?

    # Cleanup
    docker rm -f "${container_id}" > /dev/null 2>&1

    if [[ ${exit_code} -eq 0 ]]; then
        log_success "✓ ${test_name} PASSED"
        return 0
    else
        log_error "✗ ${test_name} FAILED (exit code: ${exit_code})"
        log_error "  Log: ${TEST_RESULTS_DIR}/${test_name}.log"
        return 1
    fi
}

find_scripts() {
    local scripts=()

    # Find all .sh files in scripts directory (including subdirectories)
    while IFS= read -r -d '' script; do
        # Skip test.sh itself
        if [[ "$(basename "${script}")" != "test.sh" ]]; then
            scripts+=("${script}")
        fi
    done < <(find "${SCRIPTS_DIR}" -name "*.sh" -type f -print0)

    printf '%s\n' "${scripts[@]}"
}

main() {
    log_info "Starting installation script tests..."

    # Create test results directory
    mkdir -p "${TEST_RESULTS_DIR}"

    # Check if Docker is available
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed or not in PATH"
        exit 1
    fi

    # Pull Docker images
    log_info "Pulling Docker images..."
    for distro in "${DISTRIBUTIONS[@]}"; do
        log_info "Pulling ${distro}..."
        docker pull "${distro}" > /dev/null 2>&1 || {
            log_error "Failed to pull ${distro}"
            exit 1
        }
    done

    local total=0
    local passed=0
    local failed=0
    local failed_tests=()

    # Get list of scripts
    mapfile -t scripts < <(find_scripts)

    if [[ ${#scripts[@]} -eq 0 ]]; then
        log_error "No scripts found in ${SCRIPTS_DIR}"
        exit 1
    fi

    log_info "Found ${#scripts[@]} scripts to test"

    # Test all scripts
    for script in "${scripts[@]}"; do
        for distro in "${DISTRIBUTIONS[@]}"; do
            total=$((total + 1))
            if test_script "${script}" "${distro}"; then
                passed=$((passed + 1))
            else
                failed=$((failed + 1))
                failed_tests+=("$(basename "${script}") on ${distro}")
            fi
        done
    done

    # Print summary
    echo ""
    echo "========================================="
    echo "Test Summary"
    echo "========================================="
    echo "Total:  ${total}"
    echo -e "Passed: ${GREEN}${passed}${NC}"
    echo -e "Failed: ${RED}${failed}${NC}"
    echo ""

    if [[ ${failed} -gt 0 ]]; then
        echo "Failed tests:"
        for test in "${failed_tests[@]}"; do
            echo "  - ${test}"
        done
        echo ""
    fi

    # Save summary to file
    {
        echo "Test Summary - $(date)"
        echo "=========================="
        echo "Total:  ${total}"
        echo "Passed: ${passed}"
        echo "Failed: ${failed}"
        echo ""
        if [[ ${failed} -gt 0 ]]; then
            echo "Failed tests:"
            for test in "${failed_tests[@]}"; do
                echo "  - ${test}"
            done
        fi
    } > "${TEST_RESULTS_DIR}/summary.txt"

    [[ ${failed} -eq 0 ]] && exit 0 || exit 1
}

# Parse arguments
SKIP_PULL=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --skip-pull)
            SKIP_PULL=true
            shift
            ;;
        --help)
            cat <<EOF
Usage: $0 [OPTIONS]

Test installation scripts in Docker containers.

OPTIONS:
    --skip-pull     Skip pulling Docker images
    --help          Show this help message

EOF
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

main "$@"

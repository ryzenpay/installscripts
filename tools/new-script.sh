#!/usr/bin/env bash
#
# Helper script to create a new installation script from template
#

set -euo pipefail

usage() {
    cat <<EOF
Usage: $0 <tool-name> [os-type]

Create a new installation script from template.

ARGUMENTS:
    tool-name     Name of the tool (e.g., kubectl, postgres, vscode)
    os-type       Optional: debian, ubuntu, or universal (default: universal)

EXAMPLES:
    # Universal tool (works on all Linux)
    $0 kubectl

    # Debian-specific tool
    $0 docker debian

    # Ubuntu-specific tool
    $0 vscode ubuntu

EOF
    exit 1
}

# Parse arguments
if [[ $# -lt 1 ]]; then
    usage
fi

TOOL_NAME="$1"
OS_TYPE="${2:-universal}"

TEMPLATE_FILE="templates/TEMPLATE.sh"

# Determine output path
if [[ "${OS_TYPE}" == "universal" ]]; then
    OUTPUT_FILE="scripts/${TOOL_NAME}.sh"
else
    OUTPUT_FILE="scripts/${OS_TYPE}/${TOOL_NAME}.sh"
fi

# Validate inputs
if [[ ! "${OS_TYPE}" =~ ^(debian|ubuntu|universal)$ ]]; then
    echo "Error: os-type must be 'debian', 'ubuntu', or 'universal'"
    echo ""
    usage
fi

if [[ ! -f "${TEMPLATE_FILE}" ]]; then
    echo "Error: Template file not found: ${TEMPLATE_FILE}"
    exit 1
fi

# Create directory if needed
if [[ "${OS_TYPE}" != "universal" ]]; then
    mkdir -p "scripts/${OS_TYPE}"
fi

# Check if file already exists
if [[ -f "${OUTPUT_FILE}" ]]; then
    echo "Error: Script already exists: ${OUTPUT_FILE}"
    echo "Remove it first or choose a different name."
    exit 1
fi

# Copy template
cp "${TEMPLATE_FILE}" "${OUTPUT_FILE}"

# Make executable
chmod +x "${OUTPUT_FILE}"

# Display next steps
cat <<EOF
✓ Created ${OUTPUT_FILE}

Next steps:
  1. Edit the file and customize:
     - TOOL_NAME, TOOL_DISPLAY_NAME, TOOL_DESCRIPTION
     - TOOL_SOURCE_URL
     - SUPPORTED_OS (currently: "${OS_TYPE}")
     - check_if_installed()
     - verify_installation_works()
     - install_tool() - implement your installation logic here

  2. Test locally:
     bash ${OUTPUT_FILE} --dry-run

  3. Validate compliance:
     bash tools/validate-scripts.sh

  4. Rebuild and deploy:
     docker compose up -d --build

Your script will be available at:
  http://localhost:8000/${TOOL_NAME}

EOF

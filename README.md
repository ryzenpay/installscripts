# Installation Scripts

One-line installations for Linux tools via HTTP. Simple, standardized, self-documented bash scripts.

## Quick Start

```bash
# Start server
docker compose up -d

# Install a tool
curl -sfL http://localhost:8000/helm | sh
```

Visit **http://localhost:8000** for the web UI.

---

## Folder Structure

```
scripts/
  debian/
    docker.sh          # Debian-specific
  ubuntu/
    docker.sh          # Ubuntu-specific
  helm.sh              # Universal (works on all Linux)
  kubectl.sh
  ansible.sh
```

- **scripts/*.sh** - Universal scripts (work on any Linux)
- **scripts/debian/*.sh** - Debian-specific
- **scripts/ubuntu/*.sh** - Ubuntu-specific

**The web UI auto-detects your OS and serves the right version.**

---

## Adding a New Script

### 1. Copy Template

```bash
# Universal script (works everywhere)
bash tools/new-script.sh kubectl

# OS-specific script
bash tools/new-script.sh docker debian
bash tools/new-script.sh docker ubuntu
```

### 2. Edit the Script

Customize the top section (takes 60 seconds):

```bash
#!/usr/bin/env bash
readonly TOOL_NAME="kubectl"
readonly TOOL_DISPLAY_NAME="Kubectl"
readonly TOOL_DESCRIPTION="Kubernetes CLI"
readonly SUPPORTED_OS="debian ubuntu"

check_if_installed() {
    command -v kubectl &> /dev/null
}

install_tool() {
    # Your installation commands here
    curl -LO "https://dl.k8s.io/release/stable.txt"
    # ...
}

verify_installation_works() {
    kubectl version --client &> /dev/null
}
```

**The rest is automatic** - error handling, logging, OS detection, verification, help messages, etc.

### 3. Test

```bash
# Test locally
bash scripts/kubectl.sh --dry-run

# Validate
bash tools/validate-scripts.sh

# Deploy
docker compose up -d --build
```

---

## Built-in Features

Every script automatically gets:

✅ **Error handling** - `set -euo pipefail`, trap handlers, cleanup on exit  
✅ **Logging** - Timestamped logs with severity levels  
✅ **OS detection** - Validates SUPPORTED_OS  
✅ **Dependencies** - Checks and auto-installs missing packages  
✅ **Idempotency** - Safe to run multiple times  
✅ **Verification** - Post-install checks  
✅ **Help** - `--help`, `--version`, `--force`, `--dry-run`, `--no-verify`

---

## Web UI

Visit **http://localhost:8000**

**Features:**
- Alphabetical list of all scripts
- Click script name → Copies install command
- Click "View" → See syntax-highlighted script
- Multi-OS scripts → Expand to choose version
- Search functionality

**Auto OS detection:**
- `/helm` → Auto-detects OS, serves right version
- `/debian/docker` → Forces Debian version
- `/ubuntu/docker` → Forces Ubuntu version

---

## Validation & Testing

```bash
# Validate all scripts follow template
bash tools/validate-scripts.sh

# Test in Docker containers
bash tools/test-scripts.sh
```

Tests across Debian 12, Ubuntu 22.04, Ubuntu 24.04.

---

## Example Scripts

**Universal (works everywhere):**
- **helm.sh** - Upstream installer
- **kompose.sh** - Binary download
- **ansible.sh** - APT install

**OS-specific:**
- **debian/docker.sh** - Debian repositories
- **ubuntu/docker.sh** - Ubuntu repositories

See [templates/TEMPLATE.sh](templates/TEMPLATE.sh) for the full template.

---

## Common Installation Patterns

### APT Package
```bash
install_tool() {
    sudo apt-get update -qq
    sudo apt-get install -y package-name
}
```

### Binary Download
```bash
install_tool() {
    curl -L https://example.com/binary -o /tmp/tool
    chmod +x /tmp/tool
    sudo mv /tmp/tool /usr/local/bin/tool
}
```

### Repository + Install
```bash
install_tool() {
    sudo curl -fsSL https://example.com/key.gpg -o /etc/apt/keyrings/tool.asc
    echo "deb [signed-by=/etc/apt/keyrings/tool.asc] https://repo stable main" | \
        sudo tee /etc/apt/sources.list.d/tool.list
    sudo apt-get update -qq
    sudo apt-get install -y tool-package
}
```

### .deb Download
```bash
cleanup_on_exit() {
    rm -f /tmp/tool.deb
}

install_tool() {
    wget -O /tmp/tool.deb https://example.com/tool.deb
    sudo dpkg -i /tmp/tool.deb
    sudo apt-get install -f -y
}
```

---

## Tools

**`tools/new-script.sh`** - Create new script from template  
**`tools/validate-scripts.sh`** - Validate template compliance  
**`tools/test-scripts.sh`** - Docker-based testing

---

## Architecture

```
Bash Scripts → Flask → Web UI
```

**That's it.** No YAML, no database, no code generation.

- Scripts are self-contained
- Flask auto-discovers them
- OS detection happens at request time
- One source of truth (the scripts)

---

## Development Workflow

```bash
# 1. Create script
bash tools/new-script.sh redis

# 2. Edit scripts/redis.sh
vim scripts/redis.sh

# 3. Test
bash scripts/redis.sh --dry-run

# 4. Validate
bash tools/validate-scripts.sh

# 5. Deploy
docker compose up -d --build
```

Script is now available at **http://localhost:8000/redis**

---

## Project Structure

```
installscripts/
├── scripts/              # Installation scripts
│   ├── debian/*.sh
│   ├── ubuntu/*.sh
│   └── *.sh             # Universal scripts
│
├── templates/
│   ├── TEMPLATE.sh      # Copy this for new scripts
│   ├── index.html       # Web UI
│   └── view_script.html # Script viewer
│
├── tools/
│   ├── new-script.sh    # Create from template
│   ├── validate-scripts.sh  # Validate compliance
│   └── test-scripts.sh  # Docker testing
│
├── app.py               # Flask app
├── docker-compose.yml
└── Dockerfile
```

---

## CI/CD

GitHub Actions automatically:
- Runs shellcheck on all scripts
- Validates template compliance
- Tests syntax across distributions
- Builds Docker image
- Integration tests

See [.github/workflows/validate.yml](.github/workflows/validate.yml)

---

## Why This Approach?

**Simple:**
- No YAML configs
- No code generation
- Direct script editing
- One source of truth

**Consistent:**
- Template enforces structure
- Validation ensures compliance
- Standardized logging & errors

**Maintainable:**
- Git-friendly diffs
- Easy to debug (just read the script)
- Self-documenting

**Fast:**
- No build step
- Auto-discovery
- OS detection at runtime

---

## License

MIT

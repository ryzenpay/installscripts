from flask import Flask, Response, send_file, render_template, request
import os
from pathlib import Path

SCRIPTS_DIR = "scripts"

app = Flask(__name__)

def detect_os_from_request():
    """Detect OS from User-Agent header"""
    user_agent = request.headers.get('User-Agent', '').lower()

    # Check for common OS identifiers in User-Agent
    if 'ubuntu' in user_agent:
        return 'ubuntu'
    elif 'debian' in user_agent:
        return 'debian'
    elif 'linux' in user_agent:
        # Default to universal for generic Linux
        return 'universal'

    return None

def scan_scripts():
    """Scan scripts and organize alphabetically (hiding OS folders from UI)"""
    catalog = {}  # {script_name: {variants: {os_type: path}}}
    scripts_path = Path(SCRIPTS_DIR)

    for script_file in scripts_path.rglob("*.sh"):
        rel_path = script_file.relative_to(scripts_path)
        parts = rel_path.parts

        # Determine OS type and script name
        if len(parts) == 2:  # e.g., debian/docker.sh or ubuntu/docker.sh
            os_type = parts[0]  # debian, ubuntu
            script_name = parts[1].replace('.sh', '')
        else:  # e.g., helm.sh (root level = universal)
            os_type = "universal"
            script_name = parts[0].replace('.sh', '')

        # Build catalog by script name (not by OS)
        if script_name not in catalog:
            catalog[script_name] = {'variants': {}}

        catalog[script_name]['variants'][os_type] = str(rel_path)

    # Convert to list and sort alphabetically
    scripts_list = []
    for script_name, info in sorted(catalog.items()):
        scripts_list.append({
            'name': script_name,
            'variants': info['variants']
        })

    return scripts_list

@app.route("/")
def index():
    """List all available scripts organized by category"""
    scripts_by_category = scan_scripts()
    return render_template("index.html", scripts=scripts_by_category)

def find_script_variants(script_name):
    """Find all OS variants of a script"""
    variants = {}
    scripts_path = Path(SCRIPTS_DIR)

    # Search for script in all OS folders
    for script_file in scripts_path.rglob(f"{script_name}.sh"):
        rel_path = script_file.relative_to(scripts_path)
        parts = rel_path.parts

        # Determine OS type
        if len(parts) >= 2:
            os_type = parts[0]  # debian, ubuntu, common
            variants[os_type] = str(script_file)

    return variants

@app.route("/<script_name>")
@app.route("/<path:script_path>")
def get_script(script_name=None, script_path=None):
    """Serve a script file with OS detection"""
    # Use script_name or extract from path
    if script_path and '/' in script_path:
        # Explicit path like "debian/containers/docker.sh"
        full_path = Path(SCRIPTS_DIR) / script_path
        if not script_path.endswith('.sh'):
            full_path = Path(str(full_path) + '.sh')

        if full_path.is_file():
            return send_file(full_path, download_name=os.path.basename(full_path))
        else:
            return Response(f"Script not found: {script_path}", status=404)

    # Simple script name like "docker" or "helm"
    tool_name = script_path or script_name
    if tool_name.endswith('.sh'):
        tool_name = tool_name[:-3]

    # Find all variants of this script
    variants = find_script_variants(tool_name)

    if not variants:
        return Response(f"Script not found: {tool_name}", status=404)

    # Detect user's OS
    detected_os = detect_os_from_request()

    # Priority order: detected OS -> universal -> first available
    if detected_os and detected_os in variants:
        chosen_path = variants[detected_os]
    elif 'universal' in variants:
        chosen_path = variants['universal']
    elif len(variants) == 1:
        # Only one variant, use it
        chosen_path = list(variants.values())[0]
    else:
        # Multiple variants, no detection - show selection page
        return render_template("select_os.html",
                             tool_name=tool_name,
                             variants=variants)

    return send_file(chosen_path, download_name=os.path.basename(chosen_path))

@app.route("/view/<path:script_path>")
def view_script(script_path):
    """Render a script for viewing with syntax highlighting"""
    # Add .sh extension if not present
    if not script_path.endswith('.sh'):
        script_path = script_path + '.sh'

    # Find the script file
    full_path = Path(SCRIPTS_DIR) / script_path

    if not full_path.is_file():
        return Response(f"Script not found: {script_path}", status=404)

    # Read script content
    with open(full_path, 'r') as f:
        script_content = f.read()

    # Get script name for title
    script_name = os.path.basename(script_path).replace('.sh', '')

    return render_template("view_script.html",
                         script_name=script_name,
                         script_content=script_content,
                         script_path=script_path)

@app.route("/health")
def health():
    return Response("healthy", status=200)
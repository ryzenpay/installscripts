from flask import Flask, Response, send_file, render_template
import os
FOLDER = "scripts"

app = Flask(__name__)

@app.route("/")
def index():
    files = sorted(os.listdir(FOLDER))
    return render_template("index.html", files=files)

# TODO: detect os and download os version
@app.route("/<name>/")
def get_script(name):
    if not "." in name:
        name = name + ".sh" #TODO: support others
    file = os.path.join(FOLDER, f"{name}")
    if os.path.isfile(file):
        return send_file(file, download_name=os.path.basename(file))
    else:
        return Response("Not Found", status=404)

@app.route("/health")
def health():
    return Response("healthy", status=200)
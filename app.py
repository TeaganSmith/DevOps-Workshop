from flask import Flask, request, render_template, redirect, url_for, flash
import os, json, subprocess
from dotenv import load_dotenv

load_dotenv("/home/ubuntu/DevOps-Workshop/.env")

app = Flask(__name__)
app.secret_key = os.getenv("FLASK_SECRET", "supersecretkey123")

TERRAFORM_DIR = "/home/ubuntu/DevOps-Workshop/infra"
TFVARS_DIR = "/tmp"

@app.route('/')
def form():
    return render_template("form.html")

@app.route('/provision', methods=['POST'])
def provision():
    region = request.form['region']
    instance_type = request.form['instance_type']
    client_name = request.form['client_name']

    tfvars_path = os.path.join(TFVARS_DIR, f"{client_name}-vars.json")
    tfvars = {
        "aws_region": region,
        "instance_type": instance_type,
        "client_name": client_name
    }

    with open(tfvars_path, "w") as f:
        json.dump(tfvars, f)

    env = os.environ.copy()
    env["AWS_ACCESS_KEY_ID"] = os.getenv("AWS_ACCESS_KEY_ID")
    env["AWS_SECRET_ACCESS_KEY"] = os.getenv("AWS_SECRET_ACCESS_KEY")

    try:
        subprocess.run(["terraform", "init"], cwd=TERRAFORM_DIR, env=env, check=True)

        subprocess.run(["terraform", "workspace", "new", client_name], cwd=TERRAFORM_DIR, env=env, check=False)
        subprocess.run(["terraform", "workspace", "select", client_name], cwd=TERRAFORM_DIR, env=env, check=True)

        subprocess.run([
            "terraform", "apply", "-auto-approve", f"-var-file={tfvars_path}"
        ], cwd=TERRAFORM_DIR, env=env, check=True)

        flash(f"Infrastructure provisioned for {client_name}.", "success")

    except subprocess.CalledProcessError as e:
        flash(f"Provisioning failed for {client_name}.", "error")

    return redirect(url_for("status"))

@app.route('/status')
def status():
    env = os.environ.copy()
    try:
        result = subprocess.run(["terraform", "workspace", "list"],
                                cwd=TERRAFORM_DIR, env=env, capture_output=True, text=True)
        raw_workspaces = result.stdout.splitlines()
        workspaces = []

        for ws in raw_workspaces:
            cleaned = ws.replace("*", "").strip()
            if cleaned and cleaned.lower() != "default":
                workspaces.append(cleaned)
    except subprocess.CalledProcessError:
        workspaces = []

    return render_template("status.html", clients=workspaces)

@app.route('/destroy/<client_name>', methods=['POST'])
def destroy(client_name):
    tfvars_path = os.path.join(TFVARS_DIR, f"{client_name}-vars.json")

    env = os.environ.copy()
    env["AWS_ACCESS_KEY_ID"] = os.getenv("AWS_ACCESS_KEY_ID")
    env["AWS_SECRET_ACCESS_KEY"] = os.getenv("AWS_SECRET_ACCESS_KEY")

    try:
        subprocess.run(["terraform", "workspace", "select", client_name],
                       cwd=TERRAFORM_DIR, env=env, check=True)

        subprocess.run([
            "terraform", "destroy", "-auto-approve", f"-var-file={tfvars_path}"
        ], cwd=TERRAFORM_DIR, env=env, check=True)

        subprocess.run(["terraform", "workspace", "select", "default"],
                       cwd=TERRAFORM_DIR, env=env, check=True)

        subprocess.run(["terraform", "workspace", "delete", client_name],
                       cwd=TERRAFORM_DIR, env=env, check=True)

        if os.path.exists(tfvars_path):
            os.remove(tfvars_path)

        flash(f"Infrastructure destroyed for {client_name}.", "success")

    except subprocess.CalledProcessError as e:
        flash(f"Destruction failed for {client_name}.", "error")

    return redirect(url_for("status"))

if __name__ == '__main__':
    app.run(host="0.0.0.0", port=5000)

from flask import Flask, request, render_template
import os, json, subprocess

app = Flask(__name__)

# Constants
BASE_STATE_DIR = "/infra/client-state"     # Stores per-client tfvars/backend
TERRAFORM_DIR = "/infra"                   # Contains main.tf and variables.tf

@app.route('/')
def form():
    return render_template("form.html")

@app.route('/provision', methods=['POST'])
def provision():
    region = request.form['region']
    instance_type = request.form['instance_type']
    client_name = request.form['client_name']

    # Create per-client folder
    client_dir = os.path.join(BASE_STATE_DIR, client_name)
    os.makedirs(client_dir, exist_ok=True)

    # Write terraform.tfvars.json
    tfvars = {
        "aws_region": region,
        "instance_type": instance_type,
        "client_name": client_name
    }
    with open(os.path.join(client_dir, "terraform.tfvars.json"), "w") as f:
        json.dump(tfvars, f)

    # Write backend.tf.json
    backend = {
        "terraform": {
            "backend": {
                "s3": {
                    "bucket": "devops-tf-state-teagan",
                    "key": f"state/{client_name}/infra.tfstate",
                    "region": region,
                    "dynamodb_table": "terraform-locks",
                    "encrypt": True
                }
            }
        }
    }
    with open(os.path.join(client_dir, "backend.tf.json"), "w") as f:
        json.dump(backend, f)

    # Run Terraform commands
    env = os.environ.copy()
    try:
        subprocess.run(
            ["terraform", "init", "-reconfigure", f"-backend-config={os.path.join(client_dir, 'backend.tf.json')}"],
            cwd=TERRAFORM_DIR,
            env=env,
            check=True
        )
        subprocess.run(
            ["terraform", "apply", "-auto-approve", f"-var-file={os.path.join(client_dir, 'terraform.tfvars.json')}"],
            cwd=TERRAFORM_DIR,
            env=env,
            check=True
        )
    except subprocess.CalledProcessError:
        return f"<h3>Provisioning failed for {client_name}</h3><a href='/'>Try again</a>"

    return f"<h3>Infrastructure provisioned for {client_name}!</h3><a href='/'>Back</a>"

if __name__ == '__main__':
    app.run(host="0.0.0.0", port=5000)

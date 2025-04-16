from flask import Flask, request, render_template
import os, json, subprocess

app = Flask(__name__)
BASE_STATE_DIR = "/infra/client-state"

@app.route('/')
def form():
    return render_template("form.html")

@app.route('/provision', methods=['POST'])
def provision():
    region = request.form['region']
    instance_type = request.form['instance_type']
    client_name = request.form['client_name']

    client_dir = os.path.join(BASE_STATE_DIR, client_name)
    os.makedirs(client_dir, exist_ok=True)

    # Create terraform.tfvars.json
    tfvars = {
        "aws_region": region,
        "instance_type": instance_type,
        "client_name": client_name
    }

    with open(os.path.join(client_dir, "terraform.tfvars.json"), "w") as f:
        json.dump(tfvars, f)

    # Create backend.tf.json
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

    # Run Terraform in that context
    terraform_dir = "/infra"
    env = os.environ.copy()

    try:
        subprocess.run(["terraform", "init", "-reconfigure", f"-backend-config={client_dir}/backend.tf.json"], check=True, cwd=terraform_dir, env=env)
        subprocess.run(["terraform", "apply", "-auto-approve", f"-var-file={client_dir}/terraform.tfvars.json"], check=True, cwd=terraform_dir, env=env)
    except subprocess.CalledProcessError:
        return f"<h3>Failed to provision infrastructure for {client_name}</h3><a href='/'>Try again</a>"

    return f"<h3>Provisioned infrastructure for {client_name}!</h3><a href='/'>Back</a>"

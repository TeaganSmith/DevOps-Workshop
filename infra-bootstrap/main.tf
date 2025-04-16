# infra-bootstrap/main.tf

provider "aws" {
  region = var.aws_region
}

resource "aws_key_pair" "deployer" {
  key_name   = "id_rsa.pub"
  public_key = file("${path.module}/infra-key.pub")
}

resource "aws_security_group" "infra-provisioner_sg" {
  name        = "infra-provisioner"
  description = "Allow SSH and NodePort access"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "infra-provisioner_host" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.deployer.key_name
  vpc_security_group_ids      = [aws_security_group.infra-provisioner_sg.id]
  associate_public_ip_address = true

  user_data = file("cloud-init.sh")

  tags = {
    Name = "InfraProvisioner"
  }
}

output "ec2_public_ip" {
  value = aws_instance.minikube_host.public_ip
}
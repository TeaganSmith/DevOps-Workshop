provider "aws" {
  region = var.aws_region
}

# Upload public key so we can SSH into the instance
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = file(var.public_key_path)
}

# Allow SSH + NodePort access for Minikube apps
resource "aws_security_group" "minikube_sg" {
  name        = "minikube-sg"
  description = "Allow SSH and NodePort access"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "NodePort range"
    from_port   = 30000
    to_port     = 32767
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

# Launch EC2 instance for Minikube
resource "aws_instance" "minikube_host" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.deployer.key_name
  vpc_security_group_ids      = [aws_security_group.minikube_sg.id]
  associate_public_ip_address = true

  root_block_device {
  volume_size = 30  # or 50 GB
  }

  user_data = file("${path.module}/cloud-init.sh")

  tags = {
    Name = "minikube"
  }
}

# Output IP
output "minikube_ip" {
  value = aws_instance.minikube_host.public_ip
}

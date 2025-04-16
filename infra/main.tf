provider "aws" {
  region = var.aws_region
}

variable "aws_region" {}
variable "instance_type" {}
variable "client_name" {}

resource "aws_instance" "web" {
  ami           = "ami-0655cec52acf2717b"  # Ubuntu 22.04 (update as needed)
  instance_type = var.instance_type

  tags = {
    Name = var.client_name
  }
}
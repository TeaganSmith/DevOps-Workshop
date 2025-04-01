variable "aws_region" {
  description = "AWS region to deploy resources in"
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t2.micro"
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  default     = "ami-0c02fb55956c7d316" # Ubuntu Server 22.04 LTS (HVM), SSD Volume Type for us-east-1
}

variable "public_key_path" {
  description = "Path to your local public SSH key"
  default     = "~/.ssh/id_rsa.pub"
}
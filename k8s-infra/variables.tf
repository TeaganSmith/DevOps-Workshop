variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "ami_id" {
  description = "Ubuntu AMI ID"
  type        = string
  default     = "ami-0655cec52acf2717b" # Ubuntu Server 22.04 LTS (HVM), SSD Volume Type for us-east-1
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.medium"
}

variable "public_key_path" {
  description = "Path to your SSH public key"
  type        = string
  default     = "${path.module}/infra-key.pub"
}

terraform {
  backend "s3" {
    bucket         = "devops-teagan"
    key            = "state/infra-host.tfstate"
    region         = "us-east-1"
    dynamodb_table = "TF-State-Locks"
    encrypt        = true
  }
}
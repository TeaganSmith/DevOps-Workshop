provider aws {
  region = "us-east-1"
}

resource "aws_dynamodb_table" "tf-locks" {
  name = "TF-State-Locks"
  
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
    
  }
  tags = {
    Name = "TF-State-Locks"
  } 
}

resource "aws_s3_bucket" "tf_state" {
  bucket         = "devops-tf-state-teagan" # Must be globally unique
  force_destroy  = true
}
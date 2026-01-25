terraform {
  backend "s3" {
    bucket         = "terraform-state-cicd-pipeline"
    key            = "eks-cluster/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

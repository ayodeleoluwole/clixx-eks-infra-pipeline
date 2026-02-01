terraform {
  backend "s3" {
    bucket  = "mystatefile-clixxretail"
    key     = "eks/base-infrastructure/terraform.tfstate"
    region  = "us-east-2"
  }
}
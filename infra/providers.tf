provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "python-flask-app-tf-state"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}

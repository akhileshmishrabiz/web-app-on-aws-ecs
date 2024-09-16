terraform {
  required_version = "1.8.1"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.50"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.4.3"
    }
    template = {
      source  = "hashicorp/template"
      version = "2.2.0" # Update this to a compatible version
    }
  }
}

provider "aws" {
  region = var.region
}

# Using S3 backend
terraform {
  backend "s3" {
  }
}
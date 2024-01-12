# Configure Terraform
terraform {
  required_version = ">= 1.2.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}


# Configure AWS provider
provider "aws" {
  region = var.aws_region
}


# Configure resources
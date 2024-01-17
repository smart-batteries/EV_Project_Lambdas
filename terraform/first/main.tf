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


# Create ECR repos on AWS

resource "aws_ecr_repository" "repos" {
  count = length(var.function_names)

  name                 = var.function_names[count.index]
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# Create CloudWatch log groups for each lambda function

resource "aws_cloudwatch_log_group" "function_logs" {
  count = length(var.function_names)

  name                 = "/aws/lambda/${var.function_names[count.index]}"
  retention_in_days    = 0
}






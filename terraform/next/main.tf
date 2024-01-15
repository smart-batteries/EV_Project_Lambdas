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



# Call modules

module "network" {
  source = "./network"
}

module "schedules" {
  source = "./schedules"
}

module "functions" {
  source = "./functions"

  depends_on = [module.schedules]
  prss_schedule_name = module.schedules.prss_schedule_name
  prsl_schedule_name = module.schedules.prsl_schedule_name
  purge_schedule_name = module.schedules.purge_schedule_name
}

module "queue" {
  source = "./queue"

  depends_on = [module.functions]
  prss_arn = module.functions.prss_arn
  prsl_arn = module.functions.prsl_arn
  merge_arn = module.functions.merge_arn
}














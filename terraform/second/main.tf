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

module "roles" {
  source = "./roles"
}

module "queue" {
  source = "./queue"
}


module "schedules" {
  source = "./schedules"
}

module "network" {
  source = "./network"
}

module "database" {
  source = "./database"
  depends_on = [module.network]

  subnet_1_id = module.network.subnet_1_id
  subnet_2_id = module.network.subnet_2_id
  subnet_3_id = module.network.subnet_3_id
  subnet_4_id = module.network.subnet_4_id
  subnet_5_id = module.network.subnet_3_id
  subnet_6_id = module.network.subnet_4_id
  rds_to_lambda_id = module.network.rds_to_lambda_id
}


module "functions" {
  source = "./functions"
  depends_on = [module.roles, module.queue, module.schedules, module.network, module.database]

  wits_role_arn = module.roles.wits_role_arn
  merge_role_arn = module.roles.merge_role_arn
  lambda_role_arn = module.roles.lambda_role_arn

  queue_url = module.queue.queue_url

  prss_schedule_name = module.schedules.prss_schedule_name
  prsl_schedule_name = module.schedules.prsl_schedule_name
  purge_schedule_name = module.schedules.purge_schedule_name

  subnet_1_id = module.network.subnet_1_id
  subnet_2_id = module.network.subnet_2_id
  subnet_3_id = module.network.subnet_3_id
  subnet_4_id = module.network.subnet_4_id
  subnet_5_id = module.network.subnet_5_id
  subnet_6_id = module.network.subnet_6_id
  lambda_to_rds_id = module.network.lambda_to_rds_id

  rds_host = module.database.rds_host
  db_name = module.database.db_name
  username = module.database.username
  password = module.database.password
}

module "final" {
  source = "./final"
  depends_on = [module.functions]

  queue_url = module.queue.queue_url
  queue_arn = module.queue.queue_arn

  prss_arn = module.functions.prss_arn
  prsl_arn = module.functions.prsl_arn
  merge_arn = module.functions.merge_arn
  log_request_arn = module.functions.log_request_arn
  log_request_name = module.functions.log_request_name
  log_request_invoke_arn = module.functions.log_request_invoke_arn
}



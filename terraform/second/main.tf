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

module "network" {
  source       = "./network"
  home_address = var.root_home_address
}

module "database" {
  source     = "./database"
  depends_on = [module.network]

  db_username = var.root_db_username
  db_password = var.root_db_password

  rds_to_lambda_id  = module.network.rds_to_lambda_id
  connect_to_rds_id = module.network.connect_to_rds_id
}

module "functions" {
  source     = "./functions"
  depends_on = [module.roles, module.queue, module.network, module.database]

  wits_role_arn   = module.roles.wits_role_arn
  merge_role_arn  = module.roles.merge_role_arn
  lambda_role_arn = module.roles.lambda_role_arn

  client_id     = var.root_client_id
  client_secret = var.root_client_secret
  queue_url     = module.queue.queue_url

  list_subnet_ids  = module.network.list_subnet_ids
  lambda_to_rds_id = module.network.lambda_to_rds_id

  rds_host = module.database.rds_host
  db_name  = module.database.db_name
  username = module.database.username
  password = module.database.password
}

module "schedules" {
  source     = "./schedules"
  depends_on = [module.functions]

  prss_arn = module.functions.prss_arn
  prsl_arn = module.functions.prsl_arn
  purge_arn = module.functions.purge_arn
}

module "state_machine" {
  source     = "./state_machine"
  depends_on = [module.functions]

  state_machine_role_arn = module.roles.state_machine_role_arn
  log_request_arn    = module.functions.log_request_arn
  create_problem_arn = module.functions.create_problem_arn
  get_prices_arn     = module.functions.get_prices_arn
  solver_arn         = module.functions.solver_arn
}

module "penultimate" {
  source     = "./penultimate"
  depends_on = [module.state_machine]

  queue_url = module.queue.queue_url
  queue_arn = module.queue.queue_arn

  prss_arn  = module.functions.prss_arn
  prsl_arn  = module.functions.prsl_arn
  merge_arn = module.functions.merge_arn

  start_pipeline_role_arn = module.roles.start_pipeline_role_arn
  state_machine_arn       = module.state_machine.state_machine_arn
}

module "user_api" {
  source     = "./user_api"
  depends_on = [module.penultimate]

  start_pipeline_arn        = module.penultimate.start_pipeline_arn
  start_pipeline_name       = module.penultimate.start_pipeline_name
  start_pipeline_invoke_arn = module.penultimate.start_pipeline_invoke_arn

  return_result_arn        = module.functions.return_result_arn
  return_result_name       = module.functions.return_result_name
  return_result_invoke_arn = module.functions.return_result_invoke_arn
}
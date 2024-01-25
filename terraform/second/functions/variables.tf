# Output from the roles module

variable "wits_role_arn" {
  description = "ARN of execution role for PRSS & PRSL lambda functions"
  type        = string
}

variable "merge_role_arn" {
  description = "ARN of execution role for Merge lambda function"
  type        = string
}

variable "lambda_role_arn" {
  description = "ARN of execution role for other lambda functions"
  type        = string
}

variable "return_result_arn" {
  description = "ARN of execution role for the return_result functions"
  type        = string
}




# Variables from root variables file, to be added to functions as environmental variables

variable "client_id" {
  type        = string
}

variable "client_secret" {
  type        = string
}

# Output from the queue module

variable "queue_url" {
  description = "URL of queue to carry batch data from PRSS & PRSL to Merge"
  type        = string
}




# Output from the network module

variable "list_subnet_ids" {
  description = "List of default subnets"
  type        = list(string)
}

variable "lambda_to_rds_id" {
  description = "Security group to attach to Lambda functions, so they can connect to database"
  type        = string
}




# Output from the database module

variable "rds_host" {
  description = "RDS host for Lambda functions to connect to"
  type        = string
}

variable "db_name" {
  description = "Database on RDS"
  type        = string
}

variable "username" {
  description = "User to connect to RDS"
  type        = string
}

variable "password" {
  description = "Password to connec to RDS"
  type        = string
}
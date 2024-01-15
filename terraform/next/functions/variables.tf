# Output from the network module

variable "subnet_1_id" {
  description = "Subnet 1"
  type        = string
}

variable "subnet_2_id" {
  description = "Subnet 2"
  type        = string
}

variable "lambda_to_rds_id" {
  description = "Security group for Lambda functions to connect to db"
  type        = string
}




# Output from the schedules module

variable "prss_schedule_name" {
  description = "Schedule for PRSS function"
  type        = string
}

variable "prsl_schedule_name" {
  description = "Schedule for PRSL function"
  type        = string
}

variable "purge_schedule_name" {
  description = "Schedule for Purge function"
  type        = string
}





# Environmental variables to be added to functions that call the WITS API: PRSS & PRSL

variable "client_id" {
  description = "id for calling the WITS API for electricity price forecasts"
  type        = string
}

variable "client_secret" {
  description = "secret for calling the WITS API for electricity price forecasts"
  type        = string
}


# Environmental variables to be added to functions that connect to PostgreSQL: Merge, Purge, log_run_request, create_opt_problem, load_prob_prices

variable "rds_host" {
  description = "RDS host for Lambda functions to connect to"
  type        = string
}

variable "db_name" {
  description = "Database on RDS"
  type        = string
}

variable "user_name" {
  description = "User to connect to RDS"
  type        = string
}

variable "password" {
  description = "Password to connec to RDS"
  type        = string
}
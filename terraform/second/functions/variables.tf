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




# Environmental variables to be added to functions that call the WITS API: PRSS & PRSL

variable "client_id" {
  description = "id for calling the WITS API for electricity price forecasts"
  type        = string
  default     = "Nrl6u19da0OKS12Q3L2CeWUW00tBkAmG"
}

variable "client_secret" {
  description = "secret for calling the WITS API for electricity price forecasts"
  type        = string
  default     = "xWSZfFdOyfMZJp2NHS5twscTMl5SUVdO"
}

# Output from the queue module

variable "queue_url" {
  description = "URL of queue to carry batch data from PRSS & PRSL to Merge"
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




# Output from the network module

variable "subnet_1_id" {
  description = "Subnet 1"
  type        = string
}

variable "subnet_2_id" {
  description = "Subnet 2"
  type        = string
}

variable "subnet_3_id" {
  description = "Subnet 3"
  type        = string
}

variable "subnet_4_id" {
  description = "Subnet 4"
  type        = string
}

variable "subnet_5_id" {
  description = "Subnet 5"
  type        = string
}

variable "subnet_6_id" {
  description = "Subnet 6"
  type        = string
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
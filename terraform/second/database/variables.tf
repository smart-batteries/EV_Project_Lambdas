# Variables from root variables file, to be added to functions as environmental variables

variable "db_username" {
  type        = string
}

variable "db_password" {
  type        = string
}




# Output from the network module

variable "list_subnet_ids" {
  description = "List of default subnets"
  type        = list(string)
}

variable "rds_to_lambda_id" {
  description = "Security group attached to RDS, to allow connections from Lambda functions to the database"
  type        = string
}

variable "connect_to_rds_id" {
  description = "Security group attached to RDS, to allow local connection to the database, for database administration"
  type        = string
}







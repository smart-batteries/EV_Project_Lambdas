variable "aws_region" {
  description = "Region for AWS"
  type        = string
  default     = ""
}



# Variables for network module

variable "root_home_address" {
  description = "IP address of your home network (or wherever you want to connect to the RDS instance from)"
  type        = string
  default     = ""
  sensitive   = true
}



# Variables for functions module

variable "root_client_id" {
  description = "id for calling the WITS API for electricity price forecasts"
  type        = string
  default     = ""
  sensitive   = true
}

variable "root_client_secret" {
  description = "secret for calling the WITS API for electricity price forecasts"
  type        = string
  default     = ""
  sensitive   = true
}



# Variables for database module

variable "root_db_username" {
  description = "username for accessing the RDS instance"
  type        = string
  default     = ""
  sensitive   = true
}

variable "root_db_password" {
  description = "password for accessing the RDS instance"
  type        = string
  default     = ""
  sensitive   = true
}
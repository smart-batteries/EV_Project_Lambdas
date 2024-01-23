variable "aws_region" {
  description = "Region for AWS"
  type        = string
  default     = "eu-north-1"
}


# Variables for network module

variable "root_home_address" {
  description = "IP address of your home network (or wherever you want to connect to the RDS instance from)"
  type        = string
  default     = "202.138.37.42/32"
  sensitive   = true
}



# Variables for database module

variable "root_db_username" {
  description = "username for accessing the RDS instance"
  type        = string
  default     = "dbuser"
  sensitive   = true
}

variable "root_db_password" {
  description = "password for accessing the RDS instance"
  type        = string
  default     = "ANn5)NwGdX00k7XA"
  sensitive   = true
}



# Variables for functions module

variable "root_client_id" {
  description = "id for calling the WITS API for electricity price forecasts"
  type        = string
  default     = "zIL44QmYB3mNsnZeYNbWnZou7wPNwOLS"
  sensitive   = true
}

variable "root_client_secret" {
  description = "secret for calling the WITS API for electricity price forecasts"
  type        = string
  default     = "DP9hjaGzuCjmVkOd21EkM3BjJBRz2FVF"
  sensitive   = true
}
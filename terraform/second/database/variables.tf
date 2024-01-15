

variable "username" {
  description = "username for accessing the RDS instance"
  type        = string
  default     = "dbuser"
}

variable "password" {
  description = "password for accessing the RDS instance"
  type        = string
  default     = "dbpassword"
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

variable "rds_to_lambda_id" {
  description = "Security group attached to RDS, to allow connections from Lambda functions to the database"
  type        = string
}
variable "rds_host" {
  description = "RDS host for Lambda functions to connect to"
  type        = string
  default     = "db-instance.caseq5rlslmk.us-east-1.rds.amazonaws.com"
}

variable "db_name" {
  description = "Database on RDS"
  type        = string
  default     = "db1"
}

variable "user_name" {
  description = "User to connect to RDS"
  type        = string
  default     = "postgres"
}

variable "password" {
  description = "Password to connec to RDS"
  type        = string
  default     = ">%7T&]pq8WNG9%3s"
}
# Output from the functions module

variable "prss_arn" {
  description = "ARN of PRSS lambda function"
  type        = string
}

variable "prsl_arn" {
  description = "ARN of PRSL lambda function"
  type        = string
}

variable "purge_arn" {
  description = "ARN of Purge lambda function"
  type        = string
}
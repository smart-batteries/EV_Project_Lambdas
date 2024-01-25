variable "aws_region" {
  description = "Region for AWS"
  type        = string
  default     = "eu-west-1"
}

variable "function_names" {
  type    = list(string)
  default = ["prss", "prsl", "merge", "purge", "start_pipeline", "log_request", "create_problem", "get_prices", "solver", "return_result", "return_result_inner"]
}
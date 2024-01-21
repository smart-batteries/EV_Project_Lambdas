# Output from the roles module

variable "state_machine_role_arn" {
  type        = string
  description = "ARN of the state machine execution role"
}


# Output from the functions module

variable "log_request_arn" {
  type        = string
  description = "ARN of the log_request function"
}

variable "create_problem_arn" {
  type        = string
  description = "ARN of the create_problem function"
}

variable "get_prices_arn" {
  type        = string
  description = "ARN of the get_prices function"
}

variable "solver_arn" {
  type        = string
  description = "ARN of the solver function"
}
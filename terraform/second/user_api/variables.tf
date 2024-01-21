variable "start_pipeline_arn" {
  type        = string
  description = "ARN of the start_pipeline function"
}

variable "start_pipeline_name" {
  type        = string
  description = "Name of the start_pipeline function"
}

variable "start_pipeline_invoke_arn" {
  type        = string
  description = "ARN for invoking the start_pipeline function from API Gateway"
}
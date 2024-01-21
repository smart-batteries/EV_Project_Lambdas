# Output from the queue module

variable "queue_url" {
  description = "URL of queue to carry batch data from PRSS & PRSL to Merge"
  type        = string
}

variable "queue_arn" {
  description = "ARN of queue to carry batch data from PRSS & PRSL to Merge"
  type        = string
}


# Output from the functions module

variable "prss_arn" {
  type        = string
  description = "ARN of the PRSS function"
}

variable "prsl_arn" {
  type        = string
  description = "ARN of the PRSL function"
}

variable "merge_arn" {
  type        = string
  description = "ARN of the Merge function"
}



# Output from the roles module

variable "start_pipeline_role_arn" {
  description = "ARN of execution role for start_pipeline function"
  type        = string
}

# Output from the state_machine module

variable "state_machine_arn" {
  description = "ARN of the state machine that coordinates the problems pipeline"
  type        = string
}









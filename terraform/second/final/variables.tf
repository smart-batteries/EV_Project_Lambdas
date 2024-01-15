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



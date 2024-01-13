variable "aws_region" {
  description = "Region for AWS"
  type        = string
  default     = "eu-north-1"
}


variable "names" {
  type    = list(string)
  default = ["prss", "prsl"]
}
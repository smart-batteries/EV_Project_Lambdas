variable "function_names" {
  type    = list(string)
  default = ["prss", "prsl", "merge", "purge", "log_request", "create_problem", "get_prices"]
}
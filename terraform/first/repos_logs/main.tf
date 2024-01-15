resource "aws_ecr_repository" "repos" {
  count = length(var.function_names)

  name                 = var.function_names[count.index]
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}



resource "aws_cloudwatch_log_group" "function_logs" {
  count = length(var.function_names)

  name                 = "/aws/lambda/${var.function_names[count.index]}"
  retention_in_days    = 0
}





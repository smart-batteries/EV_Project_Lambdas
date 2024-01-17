output "prss_arn" {
  value = aws_lambda_function.prss.arn
}

output "prsl_arn" {
  value = aws_lambda_function.prsl.arn
}

output "merge_arn" {
  value = aws_lambda_function.merge.arn
}

output "log_request_arn" {
  value = aws_lambda_function.log_request.arn
}

output "log_request_name" {
  value = aws_lambda_function.log_request.function_name
}

output "log_request_invoke_arn" {
  value = aws_lambda_function.log_request.invoke_arn
}




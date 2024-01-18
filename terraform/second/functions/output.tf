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

output "create_problem_arn" {
  value = aws_lambda_function.create_problem.arn
}

output "get_prices_arn" {
  value = aws_lambda_function.get_prices.arn
}

output "solver_arn" {
  value = aws_lambda_function.solver.arn
}



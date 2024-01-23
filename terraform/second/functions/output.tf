output "prss_arn" {
  value = aws_lambda_function.prss.arn
}

output "prsl_arn" {
  value = aws_lambda_function.prsl.arn
}

output "merge_arn" {
  value = aws_lambda_function.merge.arn
}

output "purge_arn" {
  value = aws_lambda_function.purge.arn
}





output "log_request_arn" {
  value = aws_lambda_function.log_request.arn
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





output "return_result_arn" {
  value = aws_lambda_function.return_result.arn
}

output "return_result_name" {
  value = aws_lambda_function.return_result.function_name
}

output "return_result_invoke_arn" {
  value = aws_lambda_function.return_result.invoke_arn
}

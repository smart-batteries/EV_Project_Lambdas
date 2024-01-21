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

output "create_problem_arn" {
  value = aws_lambda_function.create_problem.arn
}

output "get_prices_arn" {
  value = aws_lambda_function.get_prices.arn
}

output "solver_arn" {
  value = aws_lambda_function.solver.arn
}



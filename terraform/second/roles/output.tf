

output "wits_role_arn" {
  value = aws_iam_role.wits_execution_role.arn
}

output "merge_role_arn" {
  value = aws_iam_role.merge_execution_role.arn
}

output "lambda_role_arn" {
  value = aws_iam_role.lambda_execution_role.arn
}

output "state_machine_role_arn" {
  value = aws_iam_role.state_machine_execution_role.arn
}


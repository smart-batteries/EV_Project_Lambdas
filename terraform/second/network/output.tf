output "list_subnet_ids" {
  value = local.list_subnet_ids
}

output "lambda_to_rds_id" {
  value = aws_security_group.lambda_to_rds.id
}

output "rds_to_lambda_id" {
  value = aws_security_group.rds_to_lambda.id
}

output "connect_to_rds_id" {
  value = aws_security_group.connect_to_rds.id
}


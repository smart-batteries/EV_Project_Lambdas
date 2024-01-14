# Subnet outputs

output "subnet_1_id" {
  value = aws_subnet.subnet_1.id
}

output "subnet_2_id" {
  value = aws_subnet.subnet_2.id
}


# Security group outputs

output "lambda_to_rds_id" {
  value = aws_security_group.lambda_to_rds.id
}

output "rds_to_lambda" {
  value = aws_security_group.rds_to_lambda.id
}


# Subnet outputs

output "subnet_1_id" {
  value = aws_subnet.subnet_1.id
}

output "subnet_2_id" {
  value = aws_subnet.subnet_2.id
}

output "subnet_3_id" {
  value = aws_subnet.subnet_3.id
}

output "subnet_4_id" {
  value = aws_subnet.subnet_4.id
}

output "subnet_5_id" {
  value = aws_subnet.subnet_5.id
}

output "subnet_6_id" {
  value = aws_subnet.subnet_6.id
}





# Security group outputs

output "lambda_to_rds_id" {
  value = aws_security_group.lambda_to_rds.id
}

output "rds_to_lambda_id" {
  value = aws_security_group.rds_to_lambda.id
}


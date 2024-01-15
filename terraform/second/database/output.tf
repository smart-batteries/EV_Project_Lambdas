
output "rds_host" {
  value = aws_db_instance.rds_instance.address
}

output "db_name" {
  value = aws_db_instance.rds_instance.db_name
}

output "username" {
  value = aws_db_instance.rds_instance.username
}

output "password" {
  value = aws_db_instance.rds_instance.password
}



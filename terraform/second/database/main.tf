resource "aws_db_subnet_group" "db_subnets" {
  name       = "db_subnets"
  subnet_ids = var.list_subnet_ids
}

resource "aws_db_instance" "rds_instance" {
  identifier              = "rds"
  allocated_storage       = 20
  db_name                 = "forecasts_db"
  engine                  = "postgres"
  engine_version          = "15"
  instance_class          = "db.t3.micro"
  username                = var.db_username
  password                = var.db_password

  db_subnet_group_name    = aws_db_subnet_group.db_subnets.name
  vpc_security_group_ids  = [var.rds_to_lambda_id]
  backup_retention_period = 1
  deletion_protection     = true
  skip_final_snapshot     = true
}
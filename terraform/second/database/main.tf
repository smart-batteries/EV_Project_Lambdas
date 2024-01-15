
resource "aws_db_subnet_group" "db_subnets" {
  name       = "db_subnets"
  subnet_ids = [var.subnet_1_id, var.subnet_2_id, var.subnet_3_id, var.subnet_4_id, var.subnet_5_id, var.subnet_6_id]
}

resource "aws_db_instance" "rds_instance" {
  identifier              = "rds"
  allocated_storage       = 20
  db_name                 = "forecasts_db"
  engine                  = "postgres"
  engine_version          = "15"
  instance_class          = "db.t3.micro"
  username                = var.username
  password                = var.password

  db_subnet_group_name    = aws_db_subnet_group.db_subnets.name
  vpc_security_group_ids  = [var.rds_to_lambda_id]
  backup_retention_period = 1
  deletion_protection     = true
  skip_final_snapshot     = true
}
data "aws_security_group" "default" {
  name = "default"
}

resource "aws_db_instance" "rds_instance" {
  identifier              = "EV_Project_database"
  allocated_storage       = 20
  db_name                 = "forecasts_db"
  engine                  = "postgres"
  engine_version          = "15"
  instance_class          = "db.t3.micro"
  username                = var.db_username
  password                = var.db_password

  vpc_security_group_ids          = [var.rds_to_lambda_id, var.connect_to_rds_id, data.aws_security_group.default.id ]
  publicly_accessible             = true
  enabled_cloudwatch_logs_exports = ["postgresql"]
  backup_retention_period         = 1
#  deletion_protection             = true
  skip_final_snapshot             = true
}
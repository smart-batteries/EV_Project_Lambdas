
# Create VPC

resource "aws_vpc" "vpc_main" {
  cidr_block = "10.0.0.0/16"
}


# Create subnets

resource "aws_subnet" "subnet_1" {
  vpc_id     = aws_vpc.vpc_main.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_subnet" "subnet_2" {
  vpc_id     = aws_vpc.vpc_main.id
  cidr_block = "10.0.2.0/24"
}

resource "aws_subnet" "subnet_3" {
  vpc_id     = aws_vpc.vpc_main.id
  cidr_block = "10.0.3.0/24"
}

resource "aws_subnet" "subnet_4" {
  vpc_id     = aws_vpc.vpc_main.id
  cidr_block = "10.0.4.0/24"
}

resource "aws_subnet" "subnet_5" {
  vpc_id     = aws_vpc.vpc_main.id
  cidr_block = "10.0.5.0/24"
}

resource "aws_subnet" "subnet_6" {
  vpc_id     = aws_vpc.vpc_main.id
  cidr_block = "10.0.6.0/24"
}

# Create security groups

resource "aws_security_group" "lambda_to_rds" {
  name        = "lambda_to_rds"
  description = "Security group attached to Lambda functions, so other security groups can refer to it, to allow connection to RDS"
  vpc_id      = aws_vpc.vpc_main.id

  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds_to_lambda" {
  name        = "rds_to_lambda"
  description = "Security group attached to RDS, to allow connections from Lambda functions to the database"
  vpc_id      = aws_vpc.vpc_main.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [aws_security_group.lambda_to_rds.id]
  }
}
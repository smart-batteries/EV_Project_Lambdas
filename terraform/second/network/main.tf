# Fetch default VPC, subnets & internet gateway

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
} # filer state = "available"

data "aws_internet_gateway" "default" {
  filter {
    name   = "attachment.vpc-id"
    values = [data.aws_vpc.default.id]
  }
}





# Build NAT gateway

# fixed IP address; requests from AWS instances will appear to come from this source address, to external hosts
resource "aws_eip" "visible_address" {
  domain     = "vpc"
  depends_on = [data.aws_internet_gateway.default]
}

resource "aws_nat_gateway" "nat_gateway" {
  connectivity_type = "public"
  allocation_id     = aws_eip.visible_address.id
  subnet_id         = data.aws_subnets.default.ids[0]
}

resource "aws_route_table" "private" {
  vpc_id = data.aws_vpc.default.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }
}

resource "aws_route_table_association" "instance" {
  subnet_id      = data.aws_subnets.default.ids[0]
  route_table_id = aws_route_table.private.id
}



# Create security groups

resource "aws_security_group" "lambda_to_rds" {
  name        = "lambda_to_rds"
  description = "Security group attached to Lambda functions, so other security groups can refer to it, to allow connection to RDS"
  vpc_id      = data.aws_vpc.default.id

  egress {
    description = "Allow all outbound traffic from the function"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds_to_lambda" {
  name        = "rds_to_lambda"
  description = "Security group attached to RDS, to allow connections from Lambda functions to the database"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description     = "Allow connections from the security group attached to Lambda functions"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda_to_rds.id]
  }
  egress {
    description = "Allow all outbound traffic from the database"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "connect_to_rds" {
  name        = "connect_to_rds"
  description = "Security group attached to RDS, to allow local connection to the database, for database administration"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Allow connections from the designated home IP address, to administrate the database"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.home_address]
  }
  egress {
    description = "Allow all outbound traffic from the database"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


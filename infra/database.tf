locals {
  db_port = 5432
}

resource "random_password" "db_pass" {
  length           = 16
  special          = true
  override_special = "!%&()-_=+[]{}<>:?"
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.prefix}-db-subnet-group"
  subnet_ids = var.private_subnet_ids
}

resource "aws_security_group" "rds" {
  name        = "${var.prefix}-rds"
  description = "Security group for RDS"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = local.db_port
    to_port     = local.db_port
    protocol    = "tcp"
    description = "Allow from private subnets"
    cidr_blocks = [for id in var.private_subnet_ids : data.aws_subnet.privates[id].cidr_block]
  }

  tags = {
    Name = "${var.prefix}-rds"
  }
}

resource "aws_db_instance" "this" {
  identifier             = "${var.prefix}-api-db"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  engine                 = "postgres"
  engine_version         = "16.2"
  username               = "demoljdc"
  db_name                = "demoljdc"
  password               = random_password.db_pass.result
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  port                   = local.db_port

  publicly_accessible = false

  skip_final_snapshot = true
}
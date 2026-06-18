resource "aws_db_subnet_group" "db_subnets" {
  name       = "${var.environment}-db-subnet-group"
  subnet_ids = var.private_db_subnets

  tags = {
    Name = "${var.environment}-db-subnet-group"
  }
}

resource "aws_db_instance" "mysql_master" {
  identifier             = "${var.environment}-mysql-master"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  storage_type           = "gp2"
  db_name                = "tasktracker"
  username               = "admin"
  password               = "devops123!" # Note: Use AWS Secrets Manager for production!
  parameter_group_name   = "default.mysql8.0"
  db_subnet_group_name   = aws_db_subnet_group.db_subnets.name
  vpc_security_group_ids = [var.db_sg_id]
  multi_az               = true # Automatically creates the standby replica in AZ 1b
  skip_final_snapshot    = true

  tags = {
    Name = "${var.environment}-mysql-master"
  }
}

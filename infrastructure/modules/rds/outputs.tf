output "db_endpoint" {
  value = aws_db_instance.mysql_master.endpoint
}

output "db_name" {
  value = aws_db_instance.mysql_master.db_name
}

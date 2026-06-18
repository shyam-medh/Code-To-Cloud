output "mgmt_vpc_id" {
  value = aws_vpc.mgmt_vpc.id
}

output "prod_vpc_id" {
  value = aws_vpc.prod_vpc.id
}

output "mgmt_public_subnets" {
  value = [aws_subnet.mgmt_public_subnet_1a.id]
}

output "prod_public_subnets" {
  value = [
    aws_subnet.prod_public_subnet_1a.id,
    aws_subnet.prod_public_subnet_1b.id
  ]
}

output "prod_private_app_subnets" {
  value = [
    aws_subnet.prod_private_app_1a.id,
    aws_subnet.prod_private_app_1b.id
  ]
}

output "prod_private_db_subnets" {
  value = [
    aws_subnet.prod_private_db_1a.id,
    aws_subnet.prod_private_db_1b.id
  ]
}

output "prod_private_rt_1a_id" {
  value = aws_route_table.prod_private_rt_1a.id
}

output "prod_private_rt_1b_id" {
  value = aws_route_table.prod_private_rt_1b.id
}

output "mgmt_public_rt_id" {
  value = aws_route_table.mgmt_public_rt.id
}

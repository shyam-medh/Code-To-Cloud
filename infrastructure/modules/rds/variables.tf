variable "environment" { type = string }
variable "prod_vpc_id" { type = string }
variable "private_db_subnets" { type = list(string) }
variable "db_sg_id" { type = string }

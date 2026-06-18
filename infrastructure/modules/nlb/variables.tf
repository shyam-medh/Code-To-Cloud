variable "environment" { type = string }
variable "prod_vpc_id" { type = string }
variable "public_subnets" { type = list(string) }
variable "private_app_subnets" { type = list(string) }
variable "public_nlb_sg_id" { type = string }
variable "internal_nlb_sg_id" { type = string }

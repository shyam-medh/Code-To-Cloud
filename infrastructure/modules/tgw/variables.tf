variable "environment" {
  type = string
}

variable "mgmt_vpc_id" {
  type = string
}

variable "prod_vpc_id" {
  type = string
}

variable "mgmt_subnets" {
  type = list(string)
}

variable "prod_subnets" {
  type = list(string)
}

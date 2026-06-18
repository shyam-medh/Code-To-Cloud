variable "aws_region" {
  description = "The AWS region to deploy the infrastructure to"
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  description = "The environment (e.g., dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "mgmt_vpc_cidr" {
  description = "CIDR block for the Management VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "prod_vpc_cidr" {
  description = "CIDR block for the Production VPC"
  type        = string
  default     = "10.1.0.0/16"
}

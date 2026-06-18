variable "environment" { type = string }
variable "mgmt_subnets" { type = list(string) }
variable "jenkins_master_sg_id" { type = string }
variable "jenkins_slave_sg_id" { type = string }
variable "ec2_profile_name" { type = string }

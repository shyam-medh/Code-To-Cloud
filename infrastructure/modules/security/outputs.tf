output "bastion_sg_id" {
  value = aws_security_group.bastion.id
}

output "public_nlb_sg_id" {
  value = aws_security_group.public_nlb.id
}

output "nginx_sg_id" {
  value = aws_security_group.nginx.id
}

output "internal_nlb_sg_id" {
  value = aws_security_group.internal_nlb.id
}

output "app_sg_id" {
  value = aws_security_group.app.id
}

output "db_sg_id" {
  value = aws_security_group.db.id
}

output "jenkins_master_sg_id" {
  value = aws_security_group.jenkins_master.id
}

output "jenkins_slave_sg_id" {
  value = aws_security_group.jenkins_slave.id
}

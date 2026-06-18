data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_instance" "jenkins_master" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = "t3.small"
  subnet_id     = var.mgmt_subnets[0]
  vpc_security_group_ids = [var.jenkins_master_sg_id]
  iam_instance_profile   = var.ec2_profile_name

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              wget -O /etc/yum.repos.d/jenkins.repo \
                  https://pkg.jenkins.io/redhat-stable/jenkins.repo
              rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
              yum upgrade -y
              dnf install java-17-amazon-corretto -y
              yum install jenkins git -y
              systemctl enable jenkins
              systemctl start jenkins
              EOF

  tags = {
    Name = "${var.environment}-jenkins-master"
  }
}

resource "aws_instance" "jenkins_slave" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = "m7i-flex.large"
  subnet_id     = var.mgmt_subnets[0]
  vpc_security_group_ids = [var.jenkins_slave_sg_id]
  iam_instance_profile   = var.ec2_profile_name

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              dnf install java-17-amazon-corretto -y
              yum install git docker -y
              systemctl enable docker
              systemctl start docker
              usermod -aG docker ec2-user
              EOF

  tags = {
    Name = "${var.environment}-jenkins-slave"
  }
}

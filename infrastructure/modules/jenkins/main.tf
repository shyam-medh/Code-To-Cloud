data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "jenkins_master" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.small"
  subnet_id     = var.mgmt_subnets[0]
  vpc_security_group_ids = [var.jenkins_master_sg_id]
  iam_instance_profile   = var.ec2_profile_name

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y openjdk-21-jdk wget gnupg2 docker.io unzip
              systemctl enable docker
              systemctl start docker
              
              curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
              unzip awscliv2.zip
              ./aws/install
              wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
              echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
              apt-get update -y
              apt-get install -y jenkins git
              usermod -aG docker jenkins
              systemctl restart jenkins
              systemctl enable jenkins
              systemctl start jenkins
              EOF

  tags = {
    Name = "${var.environment}-jenkins-master"
  }

  lifecycle {
    ignore_changes = [user_data, ami]
  }
}

resource "aws_instance" "jenkins_slave" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "m7i-flex.large"
  subnet_id     = var.mgmt_subnets[0]
  vpc_security_group_ids = [var.jenkins_slave_sg_id]
  iam_instance_profile   = var.ec2_profile_name

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y openjdk-21-jdk git docker.io unzip
              systemctl enable docker
              systemctl start docker
              usermod -aG docker ubuntu
              
              curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
              unzip awscliv2.zip
              ./aws/install
              
              docker run -d --name sonarqube -p 9000:9000 --restart unless-stopped -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true sonarqube:lts-community
              EOF

  tags = {
    Name = "${var.environment}-jenkins-slave"
  }

  lifecycle {
    ignore_changes = [user_data, ami]
  }
}

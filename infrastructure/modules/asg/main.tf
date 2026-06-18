data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_iam_role" "ec2_role" {
  name = "${var.environment}-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.environment}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# Bastion Host Launch Template
resource "aws_launch_template" "bastion" {
  name_prefix   = "${var.environment}-bastion-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = "t3.micro"

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  vpc_security_group_ids = [var.bastion_sg_id]

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.environment}-bastion"
    }
  }
}

resource "aws_autoscaling_group" "bastion" {
  name                = "${var.environment}-bastion-asg"
  vpc_zone_identifier = var.mgmt_subnets
  desired_capacity    = 1
  max_size            = 1
  min_size            = 1

  launch_template {
    id      = aws_launch_template.bastion.id
    version = "$Latest"
  }
}

# Nginx Launch Template
resource "aws_launch_template" "nginx" {
  name_prefix   = "${var.environment}-nginx-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = "t3.micro"

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  vpc_security_group_ids = [var.nginx_sg_id]

  user_data = base64encode(templatefile("${path.module}/scripts/nginx_userdata.sh", {
    internal_nlb_dns = var.internal_nlb_dns
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.environment}-nginx"
    }
  }
}

resource "aws_autoscaling_group" "nginx" {
  name                = "${var.environment}-nginx-asg"
  vpc_zone_identifier = var.private_app_subnets
  target_group_arns   = [var.nginx_tg_arn]
  desired_capacity    = 2
  max_size            = 4
  min_size            = 2

  launch_template {
    id      = aws_launch_template.nginx.id
    version = "$Latest"
  }
}

# Java App Launch Template
resource "aws_launch_template" "app" {
  name_prefix   = "${var.environment}-app-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = "t3.small"

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  vpc_security_group_ids = [var.app_sg_id]

  user_data = base64encode(file("${path.module}/scripts/app_userdata.sh"))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.environment}-java-app"
    }
  }
}

resource "aws_autoscaling_group" "app" {
  name                = "${var.environment}-app-asg"
  vpc_zone_identifier = var.private_app_subnets
  target_group_arns   = [var.app_tg_arn]
  desired_capacity    = 2
  max_size            = 4
  min_size            = 2

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }
}

# Public NLB (Internet Facing)
resource "aws_lb" "public" {
  name               = "${var.environment}-public-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = var.public_subnets
  security_groups    = [var.public_nlb_sg_id]

  tags = {
    Name = "${var.environment}-public-nlb"
  }
}

resource "aws_lb_target_group" "nginx" {
  name     = "${var.environment}-nginx-tg"
  port     = 80
  protocol = "TCP"
  vpc_id   = var.prod_vpc_id

  health_check {
    protocol = "TCP"
    port     = 80
  }
}

resource "aws_lb_listener" "public_80" {
  load_balancer_arn = aws_lb.public.arn
  port              = "80"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx.arn
  }
}

# Internal NLB
resource "aws_lb" "internal" {
  name               = "${var.environment}-internal-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = var.private_app_subnets
  security_groups    = [var.internal_nlb_sg_id]

  tags = {
    Name = "${var.environment}-internal-nlb"
  }
}

resource "aws_lb_target_group" "app" {
  name               = "${var.environment}-app-tg"
  port               = 8081
  protocol           = "TCP"
  vpc_id             = var.prod_vpc_id
  preserve_client_ip = "false"

  health_check {
    protocol = "TCP"
    port     = 8081
  }
}

resource "aws_lb_listener" "internal_80" {
  load_balancer_arn = aws_lb.internal.arn
  port              = "80"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

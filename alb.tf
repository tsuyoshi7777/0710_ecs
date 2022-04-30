# ALB本体
resource "aws_alb" "example" {
  name                       = "web"
  load_balancer_type         = "application"
  internal                   = false
  idle_timeout               = 60
  enable_deletion_protection = false

  subnets = [
    aws_subnet.public_0.id,
    aws_subnet.public_1.id,
  ]
  security_groups = [aws_security_group.example.id]
}

# リスナーの作成
resource "aws_alb_listener" "example" {
  load_balancer_arn = aws_alb.example.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.example.arn
  ssl_policy        = "ELBSecurityPolicy-2016-08"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.blue.arn
  }
}

resource "aws_alb_listener" "example2" {
  load_balancer_arn = aws_alb.example.arn
  port              = "8080"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.green.arn
  }
}

# ターゲットグループの作成
resource "aws_alb_target_group" "blue" {
  name                 = "example-target"
  vpc_id               = aws_vpc.example.id
  target_type          = "ip"
  port                 = 80
  protocol             = "HTTP"
  deregistration_delay = 300

  health_check {
    path                = "/"
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = 200
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  depends_on = [aws_alb.example]
}

resource "aws_alb_target_group" "green" {
  name                 = "example-target2"
  vpc_id               = aws_vpc.example.id
  target_type          = "ip"
  port                 = 8080
  protocol             = "HTTP"
  deregistration_delay = 300

  health_check {
    path                = "/"
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = 200
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  depends_on = [aws_alb.example]
}

resource "aws_alb_listener_rule" "example" {
  listener_arn = aws_alb_listener.example.arn
  priority     = 100
  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.blue.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

resource "aws_alb_listener_rule" "example2" {
  listener_arn = aws_alb_listener.example2.arn
  priority     = 100
  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.green.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

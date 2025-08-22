# Application Load Balancer and Target Groups
# This file creates the ALB that distributes traffic to our ECS services

# Application Load Balancer
resource "aws_lb" "wildlife" {
  name               = "wildlife-alb-ecs"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [data.aws_security_group.alb.id]
  subnets            = data.aws_subnets.public.ids

  enable_deletion_protection = false

  tags = {
    Name        = "wildlife-alb-ecs"
    Environment = "workshop"
  }
}

# Target Group for Frontend Service
resource "aws_lb_target_group" "wildlife_frontend" {
  name        = "wildlife-frontend-tg"
  port        = 5000
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name        = "wildlife-frontend-tg"
    Service     = "frontend"
    Environment = "workshop"
  }
}

# ALB Listener for HTTP traffic
resource "aws_lb_listener" "wildlife" {
  load_balancer_arn = aws_lb.wildlife.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wildlife_frontend.arn
  }
}

# TODO: The listener above has an error - it should use target_group_arn inside a forward block
# Fix the default_action block to properly reference the target group

# Target Group for Media Service (for direct API access)
resource "aws_lb_target_group" "wildlife_media" {
  name        = "wildlife-media-tg"
  port        = 5000
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name        = "wildlife-media-tg"
    Service     = "media"
    Environment = "workshop"
  }
}

# Listener Rule for Media Service API paths
resource "aws_lb_listener_rule" "wildlife_media" {
  listener_arn = aws_lb_listener.wildlife.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wildlife_media.arn
  }

  condition {
    path_pattern {
      values = ["/wildlife/api/*"]
    }
  }
}
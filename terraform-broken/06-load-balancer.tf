# Application Load Balancer for Wildlife Application
# Creates ALB, target group, and listener for frontend service

# Target Group for Frontend Service
resource "aws_lb_target_group" "frontend" {
  name        = "wildlife-targetgroup-ecs"
  port        = 5000
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/wildlife/health"
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  ip_address_type = "ipv4"

  tags = {
    Name         = "wildlife-targetgroup-ecs"
    resourcetype = "network"
    codeblock    = "loadbalancer"
  }
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "wildlife-alb-ecs"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [data.aws_security_group.alb.id]
  subnets            = data.aws_subnets.public.ids

  enable_deletion_protection = false

  tags = {
    Name         = "wildlife-alb-ecs"
    resourcetype = "network"
    codeblock    = "loadbalancer"
  }
}

# Listener for HTTP traffic
resource "aws_lb_listener" "frontend" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }

  tags = {
    Name         = "wildlife-alb-listener"
    resourcetype = "network"
    codeblock    = "loadbalancer"
  }
}

# Output for accessing the application
output "application_url" {
  description = "URL to access the Wildlife application"
  value       = "http://${aws_lb.main.dns_name}/wildlife"
}

# Security Group Rule to allow public HTTP access to ALB
resource "aws_security_group_rule" "alb_http_public" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = data.aws_security_group.alb.id
  description       = "Allow HTTP access from anywhere"
}
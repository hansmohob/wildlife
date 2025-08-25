# Application Load Balancer for Application traffic

# Target Group for Frontend Service
# checkov:skip=CKV_AWS_378:Target group uses HTTP for workshop environment. Consider end-to-end HTTPS if certificate management overhead is acceptable.
resource "aws_lb_target_group" "frontend" {
  name        = "${var.PrefixCode}-targetgroup-ecs"
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
    Name         = "${var.PrefixCode}-targetgroup-ecs"
    resourcetype = "network"
    codeblock    = "load-balancer"
  }
}

# Application Load Balancer
# checkov:skip=CKV2_AWS_20:ALB uses HTTP for workshop environment. Consider end-to-end HTTPS if certificate management overhead is acceptable.
# checkov:skip=CKV2_AWS_28:WAF not implemented for development environment. Consider WAF for production.
resource "aws_lb" "main" {
  name               = "${var.PrefixCode}-alb-ecs"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [data.aws_security_group.alb.id]
  subnets            = data.aws_subnets.public.ids

  enable_deletion_protection = false
  
  # Security: Drop invalid HTTP headers to prevent request smuggling and injection attacks
  drop_invalid_header_fields = true

  # Enable access logging for monitoring and troubleshooting
  access_logs {
    bucket  = var.logs_s3_bucket_name
    prefix  = "alb-logs"
    enabled = true
  }

  tags = {
    Name         = "${var.PrefixCode}-alb-ecs"
    resourcetype = "network"
    codeblock    = "load-balancer"
  }
}

# Listener for HTTP traffic
# checkov:skip=CKV_AWS_2:ALB uses HTTP for workshop environment. Consider end-to-end HTTPS if certificate management overhead is acceptable.
# checkov:skip=CKV_AWS_103:TLS check not applicable - ALB uses HTTP for workshop environment. Consider end-to-end HTTPS if certificate management overhead is acceptable.
resource "aws_lb_listener" "frontend" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }

  tags = {
    Name         = "${var.PrefixCode}-alb-listener"
    resourcetype = "network"
    codeblock    = "load-balancer"
  }
}

# Output for accessing the application
output "application_url" {
  description = "URL to access the application"
  value       = "http://${aws_lb.main.dns_name}/wildlife"
}

# Security Group Rule to allow public HTTP access to ALB
# checkov:skip=CKV_AWS_260:Public HTTP access required for workshop ALB. In production, consider restricting to specific IP ranges or using CloudFront.
resource "aws_security_group_rule" "alb_http_public" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = data.aws_security_group.alb.id
  description       = "Allow HTTP access from anywhere"
}
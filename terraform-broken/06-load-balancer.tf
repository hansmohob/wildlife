# Application Load Balancer for Application

# Target Group for Frontend Service
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
# checkov:skip=CKV_AWS_150:Deletion protection disabled for workshop environment to allow terraform destroy and automated cleanup. In production, enable deletion protection for safety.
resource "aws_lb" "main" {
  name               = "${var.PrefixCode}-alb-ecs"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [data.aws_security_group.alb.id]
  subnets            = data.aws_subnets.public.ids
# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.PrefixCode}-alb-ecs"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [data.aws_security_group.alb.id]
  subnets            = data.aws_subnets.public.ids

  enable_deletion_protection = false

  tags = {
    Name         = "${var.PrefixCode}-alb-ecs"
    resourcetype = "network"
    codeblock    = "load-balancer"
  }
}

# Listener for HTTP traffic
resource "aws_lb_listener" "frontend" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  enable_deletion_protection = false
  drop_invalid_header_fields = true
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }

<<<<<<< HEAD
  access_logs {
    bucket  = data.aws_s3_bucket.wildlife_images.bucket
    prefix  = "alb-access-logs"
    enabled = true
  }

=======
>>>>>>> a408d3cff0c2ac8f476bcae75055f6655fff6ed9
  tags = {
<<<<<<< HEAD
    Name         = "${var.PrefixCode}-alb-ecs"
    resourcetype = "network"
    codeblock    = "load-balancer"
=======
    Name         = "${var.PrefixCode}-alb-listener"
    resourcetype = "network"
    codeblock    = "load-balancer"
>>>>>>> a408d3cff0c2ac8f476bcae75055f6655fff6ed9
  }
}

<<<<<<< HEAD
# Listener for HTTP traffic
# checkov:skip=CKV_AWS_2:WARNING - HTTP used for workshop simplicity. In production, always use HTTPS with proper SSL certificates.
resource "aws_lb_listener" "frontend" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"
=======
# Output for accessing the application
output "application_url" {
  description = "URL to access the application"
  value       = "http://${aws_lb.main.dns_name}/wildlife"
}
>>>>>>> a408d3cff0c2ac8f476bcae75055f6655fff6ed9

<<<<<<< HEAD
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }

  tags = {
    Name         = "${var.PrefixCode}-alb-listener"
    resourcetype = "network"
    codeblock    = "load-balancer"
  }
=======
# Security Group Rule to allow public HTTP access to ALB
resource "aws_security_group_rule" "alb_http_public" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = data.aws_security_group.alb.id
  description       = "Allow HTTP access from anywhere"
>>>>>>> a408d3cff0c2ac8f476bcae75055f6655fff6ed9
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
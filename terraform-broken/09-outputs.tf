# Terraform Outputs for Wildlife Application
# This file defines the outputs that will be displayed after deployment

# ALB DNS name for accessing the application
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.wildlife.dns_name
}

# ALB URL for easy access
output "application_url" {
  description = "URL to access the wildlife application"
  value       = "http://${aws_lb.wildlife.dns_name}"
}

# ECS Cluster information
output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.wildlife.name
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.wildlife.arn
}

# ECR Repository URLs for container images
output "ecr_repositories" {
  description = "ECR repository URLs for container images"
  value = {
    frontend = aws_ecr_repository.wildlife_frontend.repository_url
    media    = aws_ecr_repository.wildlife_media.repository_url
    # TODO: Add outputs for the missing ECR repositories
    # dataapi, alerts, and datadb repository URLs should be included here
  }
}

# Service Discovery namespace
output "service_discovery_namespace" {
  description = "Service discovery namespace for internal communication"
  value       = aws_service_discovery_private_dns_namespace.wildlife.name
}

# EFS File System information
output "efs_file_system_id" {
  description = "EFS file system ID for MongoDB storage"
  value       = aws_efs_file_system.mongodb.id
}

# VPC and networking information
output "vpc_id" {
  description = "VPC ID where resources are deployed"
  value       = data.aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "Private subnet IDs where ECS tasks run"
  value       = data.aws_subnets.private.ids
}

output "public_subnet_ids" {
  description = "Public subnet IDs where ALB is deployed"
  value       = data.aws_subnets.public.ids
}

# Service endpoints for internal communication
output "service_endpoints" {
  description = "Internal service endpoints for microservice communication"
  value = {
    frontend = "wildlife-frontend.wildlife"
    media    = "wildlife-media.wildlife"
    database = "wildlife-datadb.wildlife"
    # TODO: Add endpoints for dataapi and alerts services
    # Format: "service-name.wildlife"
  }
}

# CloudWatch Log Groups
output "log_groups" {
  description = "CloudWatch log groups for monitoring"
  value = {
    cluster  = aws_cloudwatch_log_group.ecs_cluster.name
    frontend = aws_cloudwatch_log_group.wildlife_frontend.name
    media    = aws_cloudwatch_log_group.wildlife_media.name
    # TODO: Add log group names for the missing services
  }
}

# TODO: There's an issue with one of the outputs above
# The ECR repositories output references repositories that don't exist yet
# This will cause a Terraform error when the missing repositories aren't defined
# Make sure all referenced resources actually exist in the configuration

# ECS Cluster and CloudWatch Log Groups
# This file creates the ECS cluster and logging infrastructure

# CloudWatch Log Group for ECS cluster
resource "aws_cloudwatch_log_group" "ecs_cluster" {
  name              = "/aws/ecs/wildlife-ecs"
  retention_in_days = 7

  tags = {
    Name        = "wildlife-ecs-logs"
    Environment = "workshop"
  }
}

# ECS Cluster with Container Insights enabled
resource "aws_ecs_cluster" "wildlife" {
  name = "wildlife-ecs"

  configuration {
    execute_command_configuration {
      logging = "OVERRIDE"

      log_configuration {
        cloud_watch_log_group_name = aws_cloudwatch_log_group.ecs_cluster.name
      }
    }
  }

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "wildlife-ecs"
    Environment = "workshop"
  }
}

# ECS Cluster Capacity Provider for Fargate
resource "aws_ecs_cluster_capacity_providers" "wildlife" {
  cluster_name = aws_ecs_cluster.wildlife.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

# CloudWatch Log Groups for each service
resource "aws_cloudwatch_log_group" "wildlife_frontend" {
  name              = "/aws/ecs/wildlife-frontend"
  retention_in_days = 7

  tags = {
    Name        = "wildlife-frontend-logs"
    Service     = "frontend"
    Environment = "workshop"
  }
}

resource "aws_cloudwatch_log_group" "wildlife_media" {
  name              = "/aws/ecs/wildlife-media"
  retention_in_days = 7

  tags = {
    Name        = "wildlife-media-logs"
    Service     = "media"
    Environment = "workshop"
  }
}

# TODO: Add CloudWatch Log Groups for the remaining services
# wildlife-dataapi, wildlife-alerts, wildlife-datadb
# Hint: Follow the same pattern as the log groups above
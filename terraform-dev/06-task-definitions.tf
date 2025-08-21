# ECS Task Definitions for Wildlife Application Services
# This file defines the container specifications for each microservice

# Task Definition for Frontend Service
resource "aws_ecs_task_definition" "wildlife_frontend" {
  family                   = "wildlife-frontend"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = data.aws_iam_role.ecs_task_execution.arn
  task_role_arn            = data.aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = "wildlife-frontend"
      image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/wildlife-frontend:latest"
      essential = true

      portMappings = [
        {
          containerPort = 5000
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "MEDIA_SERVICE_URL"
          value = "http://wildlife-media.wildlife:5000"
        },
        {
          name  = "DATAAPI_SERVICE_URL"
          value = "http://wildlife-dataapi.wildlife:5000"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.wildlife_frontend.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:5000/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = {
    Name        = "wildlife-frontend"
    Service     = "frontend"
    Environment = "workshop"
  }
}

# Task Definition for Media Service
resource "aws_ecs_task_definition" "wildlife_media" {
  family                   = "wildlife-media"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = data.aws_iam_role.ecs_task_execution.arn
  task_role_arn            = data.aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = "wildlife-media"
      image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/wildlife-media:latest"
      essential = true

      portMappings = [
        {
          containerPort = 5000
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "S3_BUCKET"
          value = data.aws_s3_bucket.wildlife_images.bucket
        },
        {
          name  = "MONGODB_URL"
          value = "mongodb://wildlife-datadb.wildlife:27017/wildlife"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.wildlife_media.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:5000/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = {
    Name        = "wildlife-media"
    Service     = "media"
    Environment = "workshop"
  }
}

# Task Definition for MongoDB Database
resource "aws_ecs_task_definition" "wildlife_datadb" {
  family                   = "wildlife-datadb"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = data.aws_iam_role.ecs_task_execution.arn
  task_role_arn            = data.aws_iam_role.ecs_task.arn

  volume {
    name = "mongodb-data"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.mongodb.id
      root_directory     = "/"
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.mongodb.id
      }
    }
  }

  container_definitions = jsonencode([
    {
      name      = "wildlife-datadb"
      image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/wildlife-datadb:latest"
      essential = true

      portMappings = [
        {
          containerPort = 27017
          protocol      = "tcp"
        }
      ]

      mountPoints = [
        {
          sourceVolume  = "mongodb-data"
          containerPath = "/data/db"
          readOnly      = false
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/aws/ecs/wildlife-datadb"
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = {
        command     = ["CMD", "mongosh", "--eval", "db.adminCommand('ping')"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = {
    Name        = "wildlife-datadb"
    Service     = "database"
    Environment = "workshop"
  }
}

# TODO: Add task definitions for wildlife-dataapi and wildlife-alerts services
# Both should follow similar patterns to the services above
# DataAPI: cpu=256, memory=512, port=5000, needs MONGODB_URL environment variable
# Alerts: cpu=256, memory=512, port=5000, needs DATAAPI_SERVICE_URL environment variable
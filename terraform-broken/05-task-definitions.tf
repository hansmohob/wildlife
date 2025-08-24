# ECS Task Definitions for Wildlife Application
# Creates task definitions for all microservices using module

# Frontend Task Definition
module "task_frontend" {
  source = "./modules/ecs_task_definition"

  family                   = "wildlife-frontend-task"
  cpu                      = "1024"
  memory                   = "2048"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = data.aws_iam_role.ecs_task_execution.arn
  task_role_arn           = data.aws_iam_role.ecs_task.arn

  container_name = "wildlife-frontend"
  container_image = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.id}.amazonaws.com/wildlife/frontend:latest"
  container_port = 5000
  port_name      = "frontend-http"
  app_protocol   = "http"
  
  readonly_root_filesystem = false
  log_group               = "/aws/ecs/wildlife-frontend"

  volumes = [
    {
      name = "tmp-volume"
    }
  ]

  mount_points = [
    {
      sourceVolume  = "tmp-volume"
      containerPath = "/tmp"
      readOnly      = false
    }
  ]
}

# DataAPI Task Definition
module "task_dataapi" {
  source = "./modules/ecs_task_definition"

  family                   = "wildlife-dataapi-task"
  cpu                      = "512"
  memory                   = "1024"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = data.aws_iam_role.ecs_task_execution.arn
  task_role_arn           = data.aws_iam_role.ecs_task.arn

  container_name = "wildlife-dataapi"
  container_image = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.id}.amazonaws.com/wildlife/dataapi:latest"
  container_port = 5000
  port_name      = "data-http"
  
  readonly_root_filesystem = true
  log_group               = "/aws/ecs/wildlife-dataapi"
}

# Alerts Task Definition
module "task_alerts" {
  source = "./modules/ecs_task_definition"

  family                   = "wildlife-alerts-task"
  cpu                      = "512"
  memory                   = "1024"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = data.aws_iam_role.ecs_task_execution.arn
  task_role_arn           = data.aws_iam_role.ecs_task.arn

  container_name = "wildlife-alerts"
  container_image = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.id}.amazonaws.com/wildlife/alerts:latest"
  container_port = 5000
  port_name      = "alerts-http"
  
  readonly_root_filesystem = true
  log_group               = "/aws/ecs/wildlife-alerts"
}

# Media Task Definition (EC2)
module "task_media" {
  source = "./modules/ecs_task_definition"

  family                   = "wildlife-media-task"
  cpu                      = "512"
  memory                   = "1024"
  requires_compatibilities = ["EC2"]
  execution_role_arn       = data.aws_iam_role.ecs_task_execution.arn
  task_role_arn           = data.aws_iam_role.ecs_task.arn

  container_name = "wildlife-media"
  container_image = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.id}.amazonaws.com/wildlife/media:latest"
  container_port = 5000
  port_name      = "media-http"
  
  readonly_root_filesystem = false
  log_group               = "/aws/ecs/wildlife-media"

  # Environment variables for S3 image upload
  environment_variables = [
    {
      name  = "AWS_REGION"
      value = data.aws_region.current.id
    },
    {
      name  = "BUCKET_NAME"
      value = data.aws_s3_bucket.wildlife_images.bucket
    }
  ]
}

# DataDB Task Definition (MongoDB with EFS)
module "task_datadb" {
  source = "./modules/ecs_task_definition"

  family                   = "wildlife-datadb-task"
  cpu                      = "512"
  memory                   = "1024"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = data.aws_iam_role.ecs_task_execution.arn
  task_role_arn           = data.aws_iam_role.ecs_task.arn

  container_name = "wildlife-datadb"
  container_image = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.id}.amazonaws.com/wildlife/datadb:latest"
  container_port = 27017
  port_name      = "data-tcp"
  port_protocol  = "tcp"
  
  readonly_root_filesystem = false
  user                    = "0:0"  # Run as root for MongoDB
  log_group               = "/aws/ecs/wildlife-datadb"

  # EFS volume for MongoDB data persistence
  volumes = [
    {
      name = "mongodb-data"
      efs_volume_configuration = {
        file_system_id = aws_efs_file_system.mongodb.id
        root_directory = "/"
      }
    }
  ]

  # Mount EFS volume to MongoDB data directory
  mount_points = [
    {
      sourceVolume  = "mongodb-data"
      containerPath = "/data/db"
      readOnly      = false
    }
  ]
}
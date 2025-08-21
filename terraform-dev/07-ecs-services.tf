# ECS Services for Wildlife Application
# This file creates the ECS services that run our containers

# Service Discovery Namespace
resource "aws_service_discovery_private_dns_namespace" "wildlife" {
  name        = "wildlife"
  description = "Service discovery namespace for wildlife application"
  vpc         = data.aws_vpc.main.id

  tags = {
    Name        = "wildlife-namespace"
    Environment = "workshop"
  }
}

# Service Discovery Service for Frontend
resource "aws_service_discovery_service" "wildlife_frontend" {
  name = "wildlife-frontend"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.wildlife.id

    dns_records {
      ttl  = 10
      type = "A"
    }
  }

  tags = {
    Name        = "wildlife-frontend-discovery"
    Service     = "frontend"
    Environment = "workshop"
  }
}

# ECS Service for Frontend
resource "aws_ecs_service" "wildlife_frontend" {
  name            = "wildlife-frontend-service"
  cluster         = aws_ecs_cluster.wildlife.id
  task_definition = aws_ecs_task_definition.wildlife_frontend.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.private.ids
    security_groups  = [data.aws_security_group.app.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.wildlife_frontend.arn
    container_name   = "wildlife-frontend"
    container_port   = 5000
  }

  service_registries {
    registry_arn = aws_service_discovery_service.wildlife_frontend.arn
  }

  depends_on = [aws_lb_listener.wildlife]

  tags = {
    Name        = "wildlife-frontend-service"
    Service     = "frontend"
    Environment = "workshop"
  }
}

# Service Discovery Service for Media Service
resource "aws_service_discovery_service" "wildlife_media" {
  name = "wildlife-media"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.wildlife.id

    dns_records {
      ttl  = 10
      type = "A"
    }
  }

  tags = {
    Name        = "wildlife-media-discovery"
    Service     = "media"
    Environment = "workshop"
  }
}

# ECS Service for Media Service
resource "aws_ecs_service" "wildlife_media" {
  name            = "wildlife-media-service"
  cluster         = aws_ecs_cluster.wildlife.id
  task_definition = aws_ecs_task_definition.wildlife_media.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.private.ids
    security_groups  = [data.aws_security_group.app.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.wildlife_media.arn
    container_name   = "wildlife-media"
    container_port   = 5000
  }

  service_registries {
    registry_arn = aws_service_discovery_service.wildlife_media.arn
  }

  depends_on = [aws_ecs_service.wildlife_datadb]

  tags = {
    Name        = "wildlife-media-service"
    Service     = "media"
    Environment = "workshop"
  }
}

# Service Discovery Service for Database
resource "aws_service_discovery_service" "wildlife_datadb" {
  name = "wildlife-datadb"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.wildlife.id

    dns_records {
      ttl  = 10
      type = "A"
    }
  }

  tags = {
    Name        = "wildlife-datadb-discovery"
    Service     = "database"
    Environment = "workshop"
  }
}

# ECS Service for MongoDB Database
resource "aws_ecs_service" "wildlife_datadb" {
  name            = "wildlife-datadb-service"
  cluster         = aws_ecs_cluster.wildlife.id
  task_definition = aws_ecs_task_definition.wildlife_datadb.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.private.ids
    security_groups  = [data.aws_security_group.app.id]
    assign_public_ip = false
  }

  service_registries {
    registry_arn = aws_service_discovery_service.wildlife_datadb.arn
  }

  tags = {
    Name        = "wildlife-datadb-service"
    Service     = "database"
    Environment = "workshop"
  }
}

# TODO: Add ECS services for wildlife-dataapi and wildlife-alerts
# Both should follow similar patterns to the services above
# DataAPI: desired_count=1, depends_on=[aws_ecs_service.wildlife_datadb]
# Alerts: desired_count=1, depends_on=[aws_ecs_service.wildlife_dataapi]
# Don't forget to create their service discovery services too!
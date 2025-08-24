# ECS Services for Wildlife Application
# Creates all microservices using the ECS service module

# DataDB Service (MongoDB) - Fargate
module "service_datadb" {
  source = "./modules/ecs_service"

  service_name        = "wildlife-datadb-service"
  cluster_name        = aws_ecs_cluster.main.name
  task_definition_arn = module.task_datadb.task_definition_arn
  desired_count       = 1
  launch_type         = "FARGATE"

  subnet_ids         = data.aws_subnets.private.ids
  security_group_ids = [data.aws_security_group.app.id]
  assign_public_ip   = false

  # Service Connect configuration
  service_connect_namespace_arn = aws_service_discovery_http_namespace.wildlife.arn
  service_connect_port_name     = "data-tcp"
  service_connect_discovery_name = "wildlife-datadb"
  service_connect_port          = 27017

  # No load balancer for database
  load_balancer_enabled = false

  # ECS Exec configuration
  enable_execute_command = false
}

# DataAPI Service - Fargate
module "service_dataapi" {
  source = "./modules/ecs_service"

  service_name        = "wildlife-dataapi-service"
  cluster_name        = aws_ecs_cluster.main.name
  task_definition_arn = module.task_dataapi.task_definition_arn
  desired_count       = 2
  launch_type         = "FARGATE"

  subnet_ids         = data.aws_subnets.private.ids
  security_group_ids = [data.aws_security_group.app.id]
  assign_public_ip   = false

  # Service Connect configuration
  service_connect_namespace_arn = aws_service_discovery_http_namespace.wildlife.arn
  service_connect_port_name     = "data-http"
  service_connect_discovery_name = "wildlife-dataapi"
  service_connect_port          = 5000

  # No load balancer for API
  load_balancer_enabled = false

  # ECS Exec configuration
  enable_execute_command = false

  # Wait for DataDB to be running first
  depends_on = [module.service_datadb]
}

# Alerts Service - Fargate
module "service_alerts" {
  source = "./modules/ecs_service"

  service_name        = "wildlife-alerts-service"
  cluster_name        = aws_ecs_cluster.main.name
  task_definition_arn = module.task_alerts.task_definition_arn
  desired_count       = 2
  launch_type         = "FARGATE"

  subnet_ids         = data.aws_subnets.private.ids
  security_group_ids = [data.aws_security_group.app.id]
  assign_public_ip   = false

  # Service Connect configuration
  service_connect_namespace_arn = aws_service_discovery_http_namespace.wildlife.arn
  service_connect_port_name     = "alerts-http"
  service_connect_discovery_name = "wildlife-alerts"
  service_connect_port          = 5000

  # No load balancer for alerts
  load_balancer_enabled = false

  # ECS Exec configuration
  enable_execute_command = false

  # Wait for DataDB to be running first
  depends_on = [module.service_datadb]
}

# Media Service - EC2 (uses capacity provider)
module "service_media" {
  source = "./modules/ecs_service"

  service_name        = "wildlife-media-service"
  cluster_name        = aws_ecs_cluster.main.name
  task_definition_arn = module.task_media.task_definition_arn
  desired_count       = 2

  # Use capacity provider instead of launch type
  capacity_provider_strategy = [
    {
      capacity_provider = "wildlife-capacity-ec2"
      weight           = 1
      base             = 0
    }
  ]

  subnet_ids         = data.aws_subnets.private.ids
  security_group_ids = [data.aws_security_group.app.id]
  assign_public_ip   = false

  # Service Connect configuration
  service_connect_namespace_arn = aws_service_discovery_http_namespace.wildlife.arn
  service_connect_port_name     = "media-http"
  service_connect_discovery_name = "wildlife-media"
  service_connect_port          = 5000

  # No load balancer for media
  load_balancer_enabled = false

  # ECS Exec configuration
  enable_execute_command = false

  # Wait for DataDB to be running first
  depends_on = [module.service_datadb]
}

# Frontend Service - Fargate with Load Balancer
module "service_frontend" {
  source = "./modules/ecs_service"

  service_name        = "wildlife-frontend-service"
  cluster_name        = aws_ecs_cluster.main.name
  task_definition_arn = module.task_frontend.task_definition_arn
  desired_count       = 2
  launch_type         = "FARGATE"

  subnet_ids         = data.aws_subnets.private.ids
  security_group_ids = [data.aws_security_group.app.id]
  assign_public_ip   = false

  # Service Connect configuration
  service_connect_namespace_arn = aws_service_discovery_http_namespace.wildlife.arn
  service_connect_port_name     = "frontend-http"
  service_connect_discovery_name = "wildlife-frontend"
  service_connect_port          = 5000

  # Load balancer configuration
  load_balancer_enabled = true
  target_group_arn      = aws_lb_target_group.frontend.arn
  container_name        = "wildlife-frontend"
  container_port        = 5000

  # ECS Exec configuration
  enable_execute_command = false

  # Wait for DataDB to be running first
  depends_on = [module.service_datadb]
}
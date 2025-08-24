
module "service_datadb" {
  source = "./modules/ecs_service"

  service_name        = "${var.PrefixCode}-datadb-service"
  cluster_name        = aws_ecs_cluster.main.name
  task_definition_arn = module.task_datadb.task_definition_arn
  desired_count       = 1
  launch_type         = "FARGATE"

  subnet_ids         = data.aws_subnets.private.ids
  security_group_ids = [data.aws_security_group.app.id]
  assign_public_ip   = false

  service_connect_namespace_arn = aws_service_discovery_http_namespace.main.arn
  service_connect_port_name     = "data-tcp"
  service_connect_discovery_name = "${aws_service_discovery_http_namespace.main.name}-datadb"
  service_connect_port          = 27017

  load_balancer_enabled = false


  enable_execute_command = false
}

# DataAPI Service - Fargate
module "service_dataapi" {
  source = "./modules/ecs_service"

  service_name        = "${var.PrefixCode}-dataapi-service"
  cluster_name        = aws_ecs_cluster.main.name
  task_definition_arn = module.task_dataapi.task_definition_arn
  desired_count       = 2
  launch_type         = "FARGATE"

  subnet_ids         = data.aws_subnets.private.ids
  security_group_ids = [data.aws_security_group.app.id]
  assign_public_ip   = false

  service_connect_namespace_arn = aws_service_discovery_http_namespace.main.arn
  service_connect_port_name     = "data-http"
  service_connect_discovery_name = "${aws_service_discovery_http_namespace.main.name}-dataapi"
  service_connect_port          = 5000

  load_balancer_enabled = false

  enable_execute_command = false

  # Wait for DataDB to be running first
  depends_on = [module.service_datadb]
}

# Alerts Service - Fargate
module "service_alerts" {
  source = "./modules/ecs_service"

  service_name        = "${var.PrefixCode}-alerts-service"
  cluster_name        = aws_ecs_cluster.main.name
  task_definition_arn = module.task_alerts.task_definition_arn
  desired_count       = 2
  launch_type         = "FARGATE"

  subnet_ids         = data.aws_subnets.private.ids
  security_group_ids = [data.aws_security_group.app.id]
  assign_public_ip   = false

  service_connect_namespace_arn = aws_service_discovery_http_namespace.main.arn
  service_connect_port_name     = "alerts-http"
  service_connect_discovery_name = "${aws_service_discovery_http_namespace.main.name}-alerts"
  service_connect_port          = 5000

  load_balancer_enabled = false

  enable_execute_command = false

  # Wait for DataDB to be running first
  depends_on = [module.service_datadb]
}

# Media Service - EC2 (uses capacity provider)
module "service_media" {
  source = "./modules/ecs_service"

  service_name        = "${var.PrefixCode}-media-service"
  cluster_name        = aws_ecs_cluster.main.name
  task_definition_arn = module.task_media.task_definition_arn
  desired_count       = 2

  # Use EC2 capacity provider
  capacity_provider_strategy = [
    {
      capacity_provider = aws_ecs_capacity_provider.ec2.name
      weight           = 1
      base             = 0
    }
  ]

  subnet_ids         = data.aws_subnets.private.ids
  security_group_ids = [data.aws_security_group.app.id]
  assign_public_ip   = false

  service_connect_namespace_arn = aws_service_discovery_http_namespace.main.arn
  service_connect_port_name     = "media-http"
  service_connect_discovery_name = "${aws_service_discovery_http_namespace.main.name}-media"
  service_connect_port          = 5000

  load_balancer_enabled = false

  enable_execute_command = false

  depends_on = [module.service_datadb]
}

# Frontend Service - Fargate with Load Balancer
module "service_frontend" {
  source = "./modules/ecs_service"

  service_name        = "${var.PrefixCode}-frontend-service"
  cluster_name        = aws_ecs_cluster.main.name
  task_definition_arn = module.task_frontend.task_definition_arn
  desired_count       = 2
  launch_type         = "FARGATE"

  subnet_ids         = data.aws_subnets.private.ids
  security_group_ids = [data.aws_security_group.app.id]
  assign_public_ip   = false

  service_connect_namespace_arn = aws_service_discovery_http_namespace.main.arn
  service_connect_port_name     = "frontend-http"
  service_connect_discovery_name = "${aws_service_discovery_http_namespace.main.name}-frontend"
  service_connect_port          = 5000

  load_balancer_enabled = true
  target_group_arn      = aws_lb_target_group.frontend.arn
  container_name        = "${var.PrefixCode}-frontend"
  container_port        = 5000

  enable_execute_command = false

  # Wait for DataDB to be running first
  depends_on = [module.service_datadb]
}
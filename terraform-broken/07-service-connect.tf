# Service Connect Namespace for Wildlife Application
# Must be created before ECS services can use Service Connect

resource "aws_service_discovery_http_namespace" "wildlife" {
  name        = "wildlife"
  description = "Service Connect namespace for Wildlife application"

  tags = {
    Name         = "wildlife-namespace"
    resourcetype = "network"
    codeblock    = "serviceconnect"
  }
}
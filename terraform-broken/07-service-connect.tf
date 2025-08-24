# Service Connect Namespace for Application

resource "aws_service_discovery_http_namespace" "main" {
  name        = var.PrefixCode
  description = "Service Connect namespace for application"

  tags = {
    Name         = "${var.PrefixCode}-namespace"
    resourcetype = "network"
    codeblock    = "service-connect"
  }
}
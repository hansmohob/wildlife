# ECR Repositories for Application

# Get KMS key for ECR encryption
data "aws_kms_key" "default" {
  key_id = "alias/aws/ecr"
}

# Frontend service repository
module "ecr_frontend" {
  source      = "./modules/ecr_repository"
  name        = "${var.PrefixCode}/frontend"
  kms_key_arn = data.aws_kms_key.default.arn
}

# Data API service repository
module "ecr_dataapi" {
  source      = "./modules/ecr_repository"
  name        = "${var.PrefixCode}/dataapi"
  kms_key_arn = data.aws_kms_key.default.arn
}

# Alerts service repository
module "ecr_alerts" {
  source      = "./modules/ecr_repository"
  name        = "${var.PrefixCode}/alerts"
  kms_key_arn = data.aws_kms_key.default.arn
}

# Media service repository
module "ecr_media" {
  source      = "./modules/ecr_repository"
  name        = "${var.PrefixCode}/media"
  kms_key_arn = data.aws_kms_key.default.arn
}

# Database service repository
module "ecr_datadb" {
  source      = "./modules/ecr_repository"
  name        = "${var.PrefixCode}/datadb"
  kms_key_arn = data.aws_kms_key.default.arn
}
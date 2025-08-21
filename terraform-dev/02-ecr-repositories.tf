# ECR Repositories for Wildlife Application Microservices
# This file creates container image repositories for each service

# ECR Repository for Frontend Service
resource "aws_ecr_repository" "wildlife_frontend" {
  name                 = "wildlife-frontend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name        = "wildlife-frontend"
    Service     = "frontend"
    Environment = "workshop"
  }
}

# ECR Repository for Media Service
resource "aws_ecr_repository" "wildlife_media" {
  name                 = "wildlife-media"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name        = "wildlife-media"
    Service     = "media"
    Environment = "workshop"
  }
}

# ECR Repository for DataAPI Service
# TODO: Add the wildlife-dataapi repository here
# Hint: Follow the same pattern as the repositories above

# ECR Repository for Alerts Service  
# TODO: Add the wildlife-alerts repository here
# Hint: Follow the same pattern as the repositories above

# ECR Repository for MongoDB Database
# TODO: Add the wildlife-datadb repository here
# Hint: Follow the same pattern as the repositories above

# ECR Repository Lifecycle Policies to manage image retention
resource "aws_ecr_lifecycle_policy" "wildlife_frontend_policy" {
  repository = aws_ecr_repository.wildlife_frontend.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

resource "aws_ecr_lifecycle_policy" "wildlife_media_policy" {
  repository = aws_ecr_repository.wildlife_media.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
# Data sources for existing infrastructure created by Event Engine
# This file references all the pre-existing resources that our ECS cluster will use

# Get current AWS account and region information
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Reference the existing VPC created by Event Engine
# From CloudFormation: vpc01 with Name tag pattern: ${PrefixCode}-vpc01
data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = ["wildlife-vpc01"]
  }
}

# Reference existing public subnets for ALB
# From CloudFormation: subnetpublic01 and subnetpublic02
# Name pattern: ${PrefixCode}-subnet-public01-AvailabilityZone01
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
  filter {
    name   = "tag:Name"
    values = ["wildlife-subnet-public*"]
  }
}

# Reference existing private subnets for ECS tasks  
# From CloudFormation: subnetprivate01 and subnetprivate02
# Name pattern: ${PrefixCode}-subnet-private01-AvailabilityZone01
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
  filter {
    name   = "tag:Name"
    values = ["wildlife-subnet-private*"]
  }
}

# Reference existing security group for applications
# From CloudFormation: securitygroupcodeserver (used for app containers)
# GroupName: ${PrefixCode}-securitygroup-app
data "aws_security_group" "app" {
  filter {
    name   = "group-name"
    values = ["wildlife-securitygroup-app"]
  }
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
}

# Reference existing security group for ALB
# From CloudFormation: securitygroupalb
# GroupName: ${PrefixCode}-securitygroup-alb
data "aws_security_group" "alb" {
  filter {
    name   = "group-name"
    values = ["wildlife-securitygroup-alb"]
  }
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
}

# Reference existing IAM roles created by Event Engine
# From CloudFormation: iamroleecstaskexecution
# RoleName: ${PrefixCode}-iamrole-ecs-task-execution
data "aws_iam_role" "ecs_task_execution" {
  name = "wildlife-iamrole-ecs-task-execution"
}

# From CloudFormation: iamroleecstask  
# RoleName: ${PrefixCode}-iamrole-ecs-task
data "aws_iam_role" "ecs_task" {
  name = "wildlife-iamrole-ecs-task"
}

# Reference existing S3 bucket for wildlife images
# From CloudFormation: s3bucketwildlife (auto-generated name)
# Uses variable defined in variables.tf
data "aws_s3_bucket" "wildlife_images" {
  bucket = var.wildlife_s3_bucket_name
}

# Get availability zones for the region
data "aws_availability_zones" "available" {
  state = "available"
}
# From CloudFormation: iaminstanceprofileecs
# InstanceProfileName: ${PrefixCode}-iamprofile-ecs
data "aws_iam_instance_profile" "ecs" {
  name = "wildlife-iamprofile-ecs"
}

# Reference existing EC2 key pair created by Event Engine
# From CloudFormation: ec2keypaircodeserver
# KeyName: ${PrefixCode}-ec2-keypair
data "aws_key_pair" "main" {
  key_name = "wildlife-ec2-keypair"
}

# IAM Policy for S3 access (used for image upload fix)
data "aws_iam_policy" "s3_policy" {
  name = "wildlife-iampolicy-s3"
}

# IAM Policy for EFS access (used for persistent storage)
data "aws_iam_policy" "efs_policy" {
  name = "wildlife-iampolicy-efs"
}
# EFS File System for MongoDB Persistent Storage
# This file creates the EFS file system used by the MongoDB container

# EFS File System for MongoDB data persistence
resource "aws_efs_file_system" "mongodb" {
  creation_token = "wildlife-mongodb-${random_id.efs_token.hex}"

  performance_mode                = "generalPurpose"
  throughput_mode                 = "provisioned"
  provisioned_throughput_in_mibps = 100

  encrypted = true

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = {
    Name        = "wildlife-mongodb-efs"
    Service     = "mongodb"
    Environment = "workshop"
  }
}

# Random ID for unique EFS creation token
resource "random_id" "efs_token" {
  byte_length = 8
}

# EFS Mount Targets for each private subnet
resource "aws_efs_mount_target" "mongodb" {
  count           = length(data.aws_subnets.private.ids)
  file_system_id  = aws_efs_file_system.mongodb.id
  subnet_id       = data.aws_subnets.private.ids[count.index]
  security_groups = [data.aws_security_group.app.id]
}

# EFS Access Point for MongoDB container
resource "aws_efs_access_point" "mongodb" {
  file_system_id = aws_efs_file_system.mongodb.id

  posix_user {
    gid = 999
    uid = 999
  }

  root_directory {
    path = "/mongodb"
    creation_info {
      owner_gid   = 999
      owner_uid   = 999
      permissions = "755"
    }
  }

  tags = {
    Name        = "wildlife-mongodb-access-point"
    Service     = "mongodb"
    Environment = "workshop"
  }
}

# TODO: There's a missing resource block here
# We need an EFS backup policy to ensure data protection
# Add an aws_efs_backup_policy resource that enables automatic backups
# Hint: The resource should reference aws_efs_file_system.mongodb.id
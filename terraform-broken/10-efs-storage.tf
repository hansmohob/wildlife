# EFS Storage for Application

# Attach EFS policy to ECS task role
resource "aws_iam_role_policy_attachment" "ecs_task_efs_policy" {
  role       = data.aws_iam_role.ecs_task.name
  policy_arn = data.aws_iam_policy.efs_policy.arn
}

# EFS File System for MongoDB persistent storage
resource "aws_efs_file_system" "mongodb" {
  creation_token = "${var.PrefixCode}-mongodb"
  
  performance_mode = "generalPurpose"
  throughput_mode  = "provisioned"
  provisioned_throughput_in_mibps = 100
  encrypted = true

  tags = {
    Name         = "${var.PrefixCode}-mongodb-efs"
    resourcetype = "storage"
    codeblock    = "efs"
  }
}

# EFS Mount Targets in private subnets
resource "aws_efs_mount_target" "mongodb" {
  count = length(data.aws_subnets.private.ids)
  
  file_system_id  = aws_efs_file_system.mongodb.id
  subnet_id       = data.aws_subnets.private.ids[count.index]
  security_groups = [data.aws_security_group.app.id]
}

# IAM Policy Attachments for Wildlife Application
# Fixes image upload by attaching S3 policy to ECS task role

# Attach S3 policy to ECS task role for image upload functionality
resource "aws_iam_role_policy_attachment" "ecs_task_s3_policy" {
  role       = data.aws_iam_role.ecs_task.name
  policy_arn = data.aws_iam_policy.s3_policy.arn
}
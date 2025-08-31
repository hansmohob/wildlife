# IAM Policy Attachments for Application

# Attach S3 policy to ECS task role for image upload functionality
resource "aws_iam_role_policy_attachment" "ecs_task_s3_policy" {
  role       = data.aws_iam_role.ecs_task.name
  policy_arn = data.aws_iam_policy.application_data_policy.arn
}
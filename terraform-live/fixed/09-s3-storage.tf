# IAM Policy Attachments for Application

resource "aws_iam_role_policy_attachment" "ecs_task_s3_policy" {
  role       = data.aws_iam_role.ecs_task.name
  policy_arn = data.aws_iam_policy.application_data_policy.arn
}
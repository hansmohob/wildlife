output "task_definition_arn" {
  description = "The ARN of the task definition"
  value       = aws_ecs_task_definition.task.arn
}

output "task_definition_family" {
  description = "The family of the task definition"
  value       = aws_ecs_task_definition.task.family
}

output "task_definition_revision" {
  description = "The revision of the task definition"
  value       = aws_ecs_task_definition.task.revision
}

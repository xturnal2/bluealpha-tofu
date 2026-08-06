output "cluster_arn" {
  description = "ECS cluster ARN."
  value       = aws_ecs_cluster.this.arn
}

output "service_name" {
  description = "ECS service name."
  value       = aws_ecs_service.this.name
}

output "task_definition_arn" {
  description = "Active task definition ARN."
  value       = aws_ecs_task_definition.service.arn
}

output "task_role_arn" {
  description = "IAM role assumed by application code in the task."
  value       = aws_iam_role.task.arn
}

output "load_balancer_dns_name" {
  description = "Application Load Balancer DNS name."
  value       = aws_lb.this.dns_name
}

output "service_url" {
  description = "Load balancer URL. Internal endpoints require network connectivity."
  value       = "${var.certificate_arn != null ? "https" : "http"}://${aws_lb.this.dns_name}"
}

output "load_balancer_security_group_id" {
  description = "Security group controlling client access to the load balancer."
  value       = aws_security_group.load_balancer.id
}

output "task_security_group_id" {
  description = "Security group attached to Fargate tasks."
  value       = aws_security_group.tasks.id
}

output "log_group_name" {
  description = "CloudWatch Logs group receiving container logs."
  value       = aws_cloudwatch_log_group.service.name
}

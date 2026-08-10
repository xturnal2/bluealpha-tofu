output "service_url" {
  description = "Application URL. Internal load balancers require connected network access."
  value       = module.service.service_url
}

output "load_balancer_dns_name" {
  description = "Application Load Balancer DNS name."
  value       = module.service.load_balancer_dns_name
}

output "ecs_cluster_arn" {
  description = "ECS cluster ARN."
  value       = module.service.cluster_arn
}

output "ecs_service_name" {
  description = "ECS service name."
  value       = module.service.service_name
}

output "database_endpoint" {
  description = "Private PostgreSQL endpoint including port."
  value       = module.database.endpoint
}

output "database_credentials_secret_arn" {
  description = "RDS-managed database credential secret ARN."
  value       = module.database.master_user_secret_arn
}

output "queue_url" {
  description = "Application SQS queue URL."
  value       = module.queue.queue_url
}

output "dead_letter_queue_url" {
  description = "Application SQS dead-letter queue URL."
  value       = module.queue.dead_letter_queue_url
}

output "dynamodb_table_name" {
  description = "Application DynamoDB table name."
  value       = module.table.table_name
}

output "private_subnet_ids" {
  description = "Private subnet IDs used by ECS and RDS."
  value       = module.network.private_subnet_ids
}

output "budget_id" {
  description = "AWS Budgets identifier."
  value       = aws_budgets_budget.this.id
}

output "budget_arn" {
  description = "ARN of the budget."
  value       = aws_budgets_budget.this.arn
}

output "budget_name" {
  description = "Name of the cost budget."
  value       = aws_budgets_budget.this.name
}

output "notification_count" {
  description = "Number of configured threshold notifications."
  value       = length(var.notifications)
}

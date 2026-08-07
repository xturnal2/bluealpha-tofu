output "function_name" {
  description = "Lambda function name."
  value       = aws_lambda_function.this.function_name
}

output "function_arn" {
  description = "Lambda function ARN."
  value       = aws_lambda_function.this.arn
}

output "execution_role_arn" {
  description = "Lambda execution role ARN."
  value       = aws_iam_role.function.arn
}

output "api_id" {
  description = "API Gateway HTTP API ID."
  value       = aws_apigatewayv2_api.this.id
}

output "api_endpoint" {
  description = "Public base URL for the HTTP API."
  value       = aws_apigatewayv2_api.this.api_endpoint
}

output "function_log_group_name" {
  description = "Lambda CloudWatch log group name."
  value       = aws_cloudwatch_log_group.function.name
}

output "api_log_group_name" {
  description = "API Gateway access-log group name."
  value       = aws_cloudwatch_log_group.api.name
}

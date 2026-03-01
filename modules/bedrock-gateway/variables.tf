variable "name_prefix" { type = string }
variable "environment" { type = string }
variable "bedrock_model_id" { type = string }
variable "audit_log_group_arn" { type = string }
variable "results_table_arn" { type = string }
variable "results_table_name" { type = string }

output "lambda_function_arn" {
  value = aws_lambda_function.bedrock_gateway.arn
}

output "approval_topic_arn" {
  value = aws_sns_topic.approval_notifications.arn
}

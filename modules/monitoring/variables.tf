variable "name_prefix" { type = string }
variable "environment" { type = string }
variable "audit_log_retention_days" { type = number }
variable "anomaly_score_threshold" { type = number }
variable "kinesis_stream_name" { type = string }
variable "sagemaker_endpoint_name" {
  type    = string
  default = ""
}

output "audit_log_group_arn" {
  value = aws_cloudwatch_log_group.ai_audit.arn
}

output "audit_log_group_name" {
  value = aws_cloudwatch_log_group.ai_audit.name
}

output "results_table_arn" {
  value = aws_dynamodb_table.ai_results.arn
}

output "results_table_name" {
  value = aws_dynamodb_table.ai_results.name
}

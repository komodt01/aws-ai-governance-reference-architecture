variable "name_prefix" { type = string }
variable "environment" { type = string }
variable "sagemaker_endpoint_name" { type = string }
variable "audit_log_group_name" { type = string }
variable "kinesis_stream_arn" { type = string }

output "model_registry_name" {
  value = aws_sagemaker_model_package_group.anomaly_models.model_package_group_name
}

output "governance_alerts_topic_arn" {
  value = aws_sns_topic.governance_alerts.arn
}

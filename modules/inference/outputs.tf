
output "sagemaker_endpoint_name" {
  value = aws_sagemaker_endpoint.anomaly_detector.name
}

output "audit_log_group_name" {
  value = aws_cloudwatch_log_group.audit.name
}

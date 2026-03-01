variable "name_prefix" { type = string }
variable "environment" { type = string }
variable "model_s3_uri" { type = string }
variable "memory_size_mb" { type = number }
variable "max_concurrency" { type = number }
variable "audit_log_group_arn" { type = string }

output "endpoint_name" {
  value = aws_sagemaker_endpoint.anomaly_detector.name
}

output "endpoint_arn" {
  value = aws_sagemaker_endpoint.anomaly_detector.arn
}

output "lambda_function_arn" {
  value = aws_lambda_function.inference_invoker.arn
}

output "kinesis_stream_arn" {
  description = "ARN of the payment event ingestion stream"
  value       = module.data_pipeline.kinesis_stream_arn
}

output "kinesis_stream_name" {
  description = "Name of the payment event Kinesis stream"
  value       = module.data_pipeline.kinesis_stream_name
}

output "sagemaker_endpoint_name" {
  description = "SageMaker Serverless Inference endpoint name"
  value       = module.inference.endpoint_name
}

output "bedrock_lambda_arn" {
  description = "ARN of the Bedrock gateway Lambda function"
  value       = module.bedrock_gateway.lambda_function_arn
}

output "audit_log_group_name" {
  description = "CloudWatch log group for AI audit trail"
  value       = module.monitoring.audit_log_group_name
}

output "results_table_name" {
  description = "DynamoDB table for AI scoring results"
  value       = module.monitoring.results_table_name
}

output "model_registry_name" {
  description = "SageMaker Model Registry name"
  value       = module.governance.model_registry_name
}

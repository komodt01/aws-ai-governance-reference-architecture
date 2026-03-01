variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "owner_tag" {
  description = "Owner tag for cost allocation"
  type        = string
  default     = "platform-engineering"
}

variable "cost_center" {
  description = "Cost center for FinOps allocation"
  type        = string
}

variable "kinesis_shard_count" {
  description = "Number of Kinesis shards for payment event stream. Right-size for volume."
  type        = number
  default     = 1 # Start with 1; scale based on observed throughput
}

variable "anomaly_model_s3_uri" {
  description = "S3 URI for the trained anomaly detection model artifact"
  type        = string
}

variable "sagemaker_serverless_memory_mb" {
  description = "Memory for SageMaker Serverless Inference endpoint (1024-6144 MB)"
  type        = number
  default     = 2048
}

variable "sagemaker_serverless_max_concurrency" {
  description = "Max concurrent invocations for serverless endpoint (1-200)"
  type        = number
  default     = 10
}

variable "sagemaker_endpoint_name" {
  type = string
}

variable "bedrock_model_id" {
  description = "Amazon Bedrock model ID for exception handling"
  type        = string
  default     = "anthropic.claude-3-sonnet-20240229-v1:0"
}

variable "audit_log_retention_days" {
  description = "CloudWatch log retention for AI audit trail (regulatory minimum 90 days)"
  type        = number
  default     = 90
}

variable "anomaly_score_threshold" {
  description = "Score above which a transaction is flagged for review (0.0-1.0)"
  type        = number
  default     = 0.85
}

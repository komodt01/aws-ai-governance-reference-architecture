# AI-Enabled Payments Reference Architecture
# Root module  orchestrates all component modules
#
# Architecture decisions:
# - SageMaker Serverless Inference: pay-per-inference, no idle cost (ADR-001)
# - Amazon Bedrock: managed LLM, no model training cost (ADR-002)
# - FinOps-first: all components sized for cost efficiency (ADR-003)

locals {
  name_prefix = "ai-payments-${var.environment}"
}

#  DATA PIPELINE 
# Kinesis stream for real-time payment event ingestion
# Lambda processor for feature extraction and routing
module "data_pipeline" {
  source = "./modules/data-pipeline"

  name_prefix             = local.name_prefix
  environment             = var.environment
  kinesis_shard_count     = var.kinesis_shard_count
  anomaly_score_threshold = var.anomaly_score_threshold

  inference_function_arn = module.inference.lambda_function_arn
  bedrock_function_arn   = module.bedrock_gateway.lambda_function_arn
}

#  MONITORING & OBSERVABILITY 
# Audit log retention aligned to regulatory minimum
module "monitoring" {
  source = "./modules/monitoring"

  name_prefix              = local.name_prefix
  environment              = var.environment
  audit_log_retention_days = var.audit_log_retention_days
  anomaly_score_threshold  = var.anomaly_score_threshold
  kinesis_stream_name      = module.data_pipeline.kinesis_stream_name
  sagemaker_endpoint_name  = var.sagemaker_endpoint_name
}

#  INFERENCE LAYER 
# SageMaker Serverless Inference for anomaly detection scoring
# Pay per inference  no dedicated endpoint idle cost
module "inference" {
  source = "./modules/inference"

  name_prefix         = local.name_prefix
  environment         = var.environment
  model_s3_uri        = var.anomaly_model_s3_uri
  memory_size_mb      = var.sagemaker_serverless_memory_mb
  max_concurrency     = var.sagemaker_serverless_max_concurrency
  audit_log_group_arn = module.monitoring.audit_log_group_arn
}

#  BEDROCK GATEWAY 
# Amazon Bedrock integration for exception handling and operational automation
# Governance: all Bedrock calls logged, human approval gate enforced
module "bedrock_gateway" {
  source = "./modules/bedrock-gateway"

  name_prefix         = local.name_prefix
  environment         = var.environment
  bedrock_model_id    = var.bedrock_model_id
  audit_log_group_arn = module.monitoring.audit_log_group_arn
  results_table_arn   = module.monitoring.results_table_arn
  results_table_name  = module.monitoring.results_table_name
}

#  GOVERNANCE 
# SageMaker Model Registry, IAM least-privilege policies
# Drift detection and model performance monitoring
module "governance" {
  source = "./modules/governance"

  name_prefix             = local.name_prefix
  environment             = var.environment
  sagemaker_endpoint_name = module.inference.endpoint_name
  kinesis_stream_arn      = module.data_pipeline.kinesis_stream_arn
  audit_log_group_name    = module.inference.audit_log_group_name
}

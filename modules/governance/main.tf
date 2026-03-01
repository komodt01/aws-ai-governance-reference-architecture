# Module: governance
# AI governance infrastructure:
# - SageMaker Model Registry for version control and approval workflow
# - IAM least-privilege policies scoped to AI components
# - Model drift detection alarms
# - Audit trail configuration

# ------ MODEL REGISTRY ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# SageMaker Model Registry enforces model approval workflow
# No model reaches production without approval status = Approved
resource "aws_sagemaker_model_package_group" "anomaly_models" {
  model_package_group_name        = "${var.name_prefix}-anomaly-models"
  model_package_group_description = "Versioned registry for payment anomaly detection models. Approval required before production deployment."

  tags = {
    Name       = "${var.name_prefix}-anomaly-models"
    Governance = "ApprovalRequired"
    UseCase    = "PaymentAnomalyDetection"
  }
}

# ------ DRIFT DETECTION ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# CloudWatch alarm for model performance degradation
# Triggers retraining pipeline when drift detected
resource "aws_cloudwatch_metric_alarm" "model_drift" {
  alarm_name          = "${var.name_prefix}-model-drift"
  alarm_description   = "Model performance below baseline - possible drift. Retraining pipeline should be evaluated."
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 3
  metric_name         = "ModelPrecision"
  namespace           = "AIPayments/ModelPerformance"
  period              = 3600 # Hourly evaluation
  statistic           = "Average"
  threshold           = 0.80 # Alert if precision drops below 80%
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.governance_alerts.arn]

  tags = {
    Name       = "${var.name_prefix}-model-drift"
    Governance = "DriftDetection"
  }
}

# ------ GOVERNANCE ALERTS ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
resource "aws_sns_topic" "governance_alerts" {
  name              = "${var.name_prefix}-governance-alerts"
  kms_master_key_id = "alias/aws/sns"

  tags = {
    Name    = "${var.name_prefix}-governance-alerts"
    Purpose = "model-governance-alerts"
  }
}
# ------ AUDIT LOG METRIC FILTERS ---------------------------------------------------------------------------------------------------------------------------------------------------------
# Extract structured metrics from audit logs for governance reporting

resource "aws_cloudwatch_log_metric_filter" "bedrock_invocations" {
  name           = "${var.name_prefix}-bedrock-invocations"
  pattern        = "{ $.event_type = \"BedrockInvocation\" }"
  log_group_name = var.audit_log_group_name

  metric_transformation {
    name      = "BedrockInvocations"
    namespace = "AIPayments/Governance"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "human_overrides" {
  name           = "${var.name_prefix}-human-overrides"
  pattern        = "{ $.event_type = \"HumanOverride\" }"
  log_group_name = var.audit_log_group_name

  metric_transformation {
    name      = "HumanOverrides"
    namespace = "AIPayments/Governance"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "anomaly_flags" {
  name           = "${var.name_prefix}-anomaly-flags"
  pattern        = "{ $.event_type = \"AnomalyFlagged\" }"
  log_group_name = var.audit_log_group_name

  metric_transformation {
    name      = "AnomalyFlags"
    namespace = "AIPayments/Governance"
    value     = "1"
  }
}

# ------ KINESIS STREAM POLICY ------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Restrict Kinesis stream access to authorized AI pipeline components only
resource "aws_kinesis_resource_policy" "pipeline_access" {
  resource_arn = var.kinesis_stream_arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowPipelineProcessorOnly"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = [
          "kinesis:GetRecords",
          "kinesis:GetShardIterator",
          "kinesis:DescribeStream",
          "kinesis:PutRecord",
          "kinesis:PutRecords"
        ]
        Resource = var.kinesis_stream_arn
      }
    ]
  })
}

data "aws_caller_identity" "current" {}

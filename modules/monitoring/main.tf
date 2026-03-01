# Module: monitoring
# Observability, audit logging, and feedback loop infrastructure
#
# Regulatory requirement: All AI model inputs, outputs, and decisions
# must be logged with minimum 90-day retention.

#  AUDIT LOG GROUP 
resource "aws_cloudwatch_log_group" "ai_audit" {
  name              = "/ai-payments/${var.environment}/audit"
  retention_in_days = var.audit_log_retention_days

  tags = {
    Name       = "${var.name_prefix}-ai-audit"
    Purpose    = "AI model input/output audit trail"
    Regulatory = "Required90DayMinimum"
  }
}

#  RESULTS TABLE 
# DynamoDB table for AI scoring results and Bedrock recommendations
# Enables feedback loop analysis and model performance tracking
resource "aws_dynamodb_table" "ai_results" {
  name         = "${var.name_prefix}-ai-results"
  billing_mode = "PAY_PER_REQUEST" # On-demand - variable exception volume
  hash_key     = "transaction_id"
  range_key    = "timestamp"

  attribute {
    name = "transaction_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  attribute {
    name = "result_type"
    type = "S"
  }

  global_secondary_index {
    name            = "result-type-index"
    hash_key        = "result_type"
    range_key       = "timestamp"
    projection_type = "ALL"
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name       = "${var.name_prefix}-ai-results"
    Purpose    = "AI scoring results and Bedrock recommendation audit trail"
    PIIPresent = "false" # Store scores only, not raw payment data
  }
}

#  CLOUDWATCH ALARMS 

# Alarm: high anomaly rate - possible fraud spike or model drift
resource "aws_cloudwatch_metric_alarm" "high_anomaly_rate" {
  alarm_name          = "${var.name_prefix}-high-anomaly-rate"
  alarm_description   = "Anomaly detection score rate above threshold - investigate for fraud spike or model drift"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "AnomalyFlagRate"
  namespace           = "AIPayments/Inference"
  period              = 300 # 5-minute windows
  statistic           = "Average"
  threshold           = 0.15 # Alert if >15% of transactions flagged
  alarm_actions       = [aws_sns_topic.ops_alerts.arn]

  tags = {
    Name = "${var.name_prefix}-high-anomaly-rate"
  }
}

# Alarm: SageMaker endpoint errors - model availability
resource "aws_cloudwatch_metric_alarm" "inference_errors" {
  alarm_name          = "${var.name_prefix}-inference-errors"
  alarm_description   = "SageMaker Serverless Inference errors - model may be unavailable"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ModelError"
  namespace           = "AWS/SageMaker"
  period              = 60
  statistic           = "Sum"
  threshold           = 5
  alarm_actions       = [aws_sns_topic.ops_alerts.arn]

  dimensions = {
    EndpointName = var.sagemaker_endpoint_name
    VariantName  = "primary"
  }
}

# Alarm: Kinesis iterator age - pipeline falling behind
resource "aws_cloudwatch_metric_alarm" "kinesis_iterator_age" {
  alarm_name          = "${var.name_prefix}-kinesis-iterator-age"
  alarm_description   = "Payment event pipeline falling behind - processing lag detected"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "GetRecords.IteratorAgeMilliseconds"
  namespace           = "AWS/Kinesis"
  period              = 60
  statistic           = "Maximum"
  threshold           = 60000 # 60 second lag threshold
  alarm_actions       = [aws_sns_topic.ops_alerts.arn]

  dimensions = {
    StreamName = var.kinesis_stream_name
  }
}

# SNS topic for operational alerts
resource "aws_sns_topic" "ops_alerts" {
  name              = "${var.name_prefix}-ops-alerts"
  kms_master_key_id = "alias/aws/sns"

  tags = {
    Name    = "${var.name_prefix}-ops-alerts"
    Purpose = "AI payment operations alerts"
  }
}

#  CLOUDWATCH DASHBOARD 
resource "aws_cloudwatch_dashboard" "ai_payments" {
  dashboard_name = "${var.name_prefix}-ai-payments"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          title  = "Anomaly Detection Rate"
          region = "us-east-1"
          period = 300
          metrics = [
            ["AIPayments/Inference", "AnomalyFlagRate"]
          ]
          view  = "timeSeries"
          stat  = "Average"
          yAxis = { left = { min = 0, max = 1 } }
        }
      },
      {
        type = "metric"
        properties = {
          title  = "SageMaker Inference Latency"
          region = "us-east-1"
          period = 60
          metrics = [
            ["AWS/SageMaker",
              "ModelLatency",
              "EndpointName", tostring(var.sagemaker_endpoint_name),
              "VariantName", "primary"
            ]
          ]
          view = "timeSeries"
          stat = "p99"
        }
      },
      {
        type = "metric"
        properties = {
          title  = "Bedrock Exception Handler Invocations"
          region = "us-east-1"
          period = 300
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", "${var.name_prefix}-bedrock-gateway"]
          ]
          view = "timeSeries"
          stat = "Sum"
        }
      },
      {
        type = "metric"
        properties = {
          title  = "Payment Pipeline Lag (Kinesis Iterator Age)"
          region = "us-east-1"
          period = 60
          metrics = [
            ["AWS/Kinesis", "GetRecords.IteratorAgeMilliseconds", "StreamName", tostring(var.kinesis_stream_name)]
          ]
          view = "timeSeries"
          stat = "Maximum"
        }
      }
    ]
  })
}

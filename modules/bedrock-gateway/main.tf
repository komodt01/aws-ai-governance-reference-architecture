# Module: bedrock-gateway
# Amazon Bedrock integration for:
# 1. Payment exception handling - reasoning and resolution suggestions
# 2. Operational automation - incident triage and communication drafting
#
# Governance principle: Bedrock informs business decisions, does not make them.
# All Bedrock outputs are logged. Human approval gate enforced via EventBridge.

resource "aws_iam_role" "bedrock_lambda" {
  name = "${var.name_prefix}-bedrock-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "bedrock_lambda" {
  name = "${var.name_prefix}-bedrock-lambda-policy"
  role = aws_iam_role.bedrock_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Bedrock model invocation - scoped to specific model
        Effect   = "Allow"
        Action   = "bedrock:InvokeModel"
        Resource = "arn:aws:bedrock:*::foundation-model/${var.bedrock_model_id}"
      },
      {
        # Write results to DynamoDB for audit trail
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:GetItem"
        ]
        Resource = var.results_table_arn
      },
      {
        # Audit logging
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${var.audit_log_group_arn}:*"
      },
      {
        # EventBridge for human approval gate
        Effect   = "Allow"
        Action   = "events:PutEvents"
        Resource = "arn:aws:events:*:*:event-bus/default"
      },
      {
        Effect   = "Allow"
        Action   = ["xray:PutTraceSegments", "xray:PutTelemetryRecords"]
        Resource = "*"
      }
    ]
  })
}

# Lambda function - Bedrock gateway
# Handles exception context assembly, Bedrock invocation, result logging
resource "aws_lambda_function" "bedrock_gateway" {
  function_name = "${var.name_prefix}-bedrock-gateway"
  role          = aws_iam_role.bedrock_lambda.arn
  handler       = "index.handler"
  runtime       = "python3.12"
  timeout       = 60 # Bedrock inference can take up to 30s for complex reasoning
  memory_size   = 512

  filename = "${path.module}/placeholder.zip"

  environment {
    variables = {
      BEDROCK_MODEL_ID   = var.bedrock_model_id
      RESULTS_TABLE_NAME = var.results_table_name
      ENVIRONMENT        = var.environment
      # Governance: all Bedrock calls must be logged
      AUDIT_LOGGING = "true"
      # Governance: max tokens to control cost and response scope
      MAX_TOKENS = "1000"
    }
  }

  tracing_config {
    mode = "Active"
  }

  tags = {
    Name       = "${var.name_prefix}-bedrock-gateway"
    UseCase    = "PaymentExceptionHandling-OperationalAutomation"
    Governance = "HumanApprovalRequired"
  }
}

# EventBridge rule - human approval gate
# Bedrock outputs trigger this rule before any downstream action
resource "aws_cloudwatch_event_rule" "bedrock_approval_gate" {
  name        = "${var.name_prefix}-bedrock-approval-gate"
  description = "Governance gate: Bedrock recommendations require human review before action"

  event_pattern = jsonencode({
    source      = ["ai-payments.bedrock-gateway"]
    detail-type = ["BedrockRecommendation"]
    detail = {
      requires_approval = [true]
    }
  })

  tags = {
    Name       = "${var.name_prefix}-bedrock-approval-gate"
    Governance = "HumanApprovalGate"
  }
}

# SNS topic for human approval notifications
resource "aws_sns_topic" "approval_notifications" {
  name              = "${var.name_prefix}-approval-notifications"
  kms_master_key_id = "alias/aws/sns"

  tags = {
    Name    = "${var.name_prefix}-approval-notifications"
    Purpose = "Human approval required for AI-recommended payment actions"
  }
}

resource "aws_cloudwatch_event_target" "approval_notification" {
  rule      = aws_cloudwatch_event_rule.bedrock_approval_gate.name
  target_id = "SendApprovalNotification"
  arn       = aws_sns_topic.approval_notifications.arn
}

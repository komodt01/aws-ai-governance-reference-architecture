# Module: data-pipeline
# Kinesis Data Stream for payment event ingestion
# Lambda processor for feature extraction and inference routing

resource "aws_kinesis_stream" "payment_events" {
  name             = "${var.name_prefix}-payment-events"
  shard_count      = var.kinesis_shard_count
  retention_period = 24 # hours - sufficient for replay and audit

  stream_mode_details {
    stream_mode = "PROVISIONED"
    # Note: Switch to ON_DEMAND if payment volume is unpredictable
    # ON_DEMAND auto-scales but costs more at steady high volume
    # FinOps decision: PROVISIONED at known baseline, review quarterly
  }

  encryption_type = "KMS"
  kms_key_id      = "alias/aws/kinesis"

  tags = {
    Name       = "${var.name_prefix}-payment-events"
    DataClass  = "Confidential"
    PIIPresent = "true"
  }
}

# IAM role for Lambda processor
resource "aws_iam_role" "pipeline_processor" {
  name = "${var.name_prefix}-pipeline-processor"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "pipeline_processor" {
  name = "${var.name_prefix}-pipeline-processor-policy"
  role = aws_iam_role.pipeline_processor.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Read from Kinesis stream
        Effect = "Allow"
        Action = [
          "kinesis:GetRecords",
          "kinesis:GetShardIterator",
          "kinesis:DescribeStream",
          "kinesis:ListShards"
        ]
        Resource = aws_kinesis_stream.payment_events.arn
      },
      {
        # Invoke inference Lambda
        Effect   = "Allow"
        Action   = "lambda:InvokeFunction"
        Resource = var.inference_function_arn
      },
      {
        # Invoke Bedrock gateway Lambda for exceptions
        Effect   = "Allow"
        Action   = "lambda:InvokeFunction"
        Resource = var.bedrock_function_arn
      },
      {
        # CloudWatch logging
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        # X-Ray tracing
        Effect   = "Allow"
        Action   = ["xray:PutTraceSegments", "xray:PutTelemetryRecords"]
        Resource = "*"
      }
    ]
  })
}

# Lambda function for feature extraction and routing
resource "aws_lambda_function" "pipeline_processor" {
  function_name = "${var.name_prefix}-pipeline-processor"
  role          = aws_iam_role.pipeline_processor.arn
  handler       = "index.handler"
  runtime       = "python3.12"
  timeout       = 30
  memory_size   = 512

  # Placeholder - replace with actual deployment package
  filename = "${path.module}/placeholder.zip"

  environment {
    variables = {
      ENVIRONMENT            = var.environment
      INFERENCE_FUNCTION_ARN = var.inference_function_arn
      BEDROCK_FUNCTION_ARN   = var.bedrock_function_arn
      ANOMALY_THRESHOLD      = tostring(var.anomaly_score_threshold)
    }
  }

  tracing_config {
    mode = "Active" # X-Ray tracing for all payment processing
  }

  tags = {
    Name = "${var.name_prefix}-pipeline-processor"
  }
}

# Kinesis trigger for Lambda
resource "aws_lambda_event_source_mapping" "kinesis_trigger" {
  event_source_arn  = aws_kinesis_stream.payment_events.arn
  function_name     = aws_lambda_function.pipeline_processor.arn
  starting_position = "LATEST"
  batch_size        = 10

  destination_config {
    on_failure {
      destination_arn = aws_sqs_queue.pipeline_dlq.arn
    }
  }
}

resource "aws_iam_role_policy" "pipeline_send_sqs" {
  name = "${var.name_prefix}-pipeline-send-sqs"
  role = aws_iam_role.pipeline_processor.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:GetQueueUrl",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.pipeline_dlq.arn
      }
    ]
  })
}


# Dead letter queue for failed payment event processing
resource "aws_sqs_queue" "pipeline_dlq" {
  name                      = "${var.name_prefix}-pipeline-dlq"
  message_retention_seconds = 1209600 # 14 days - retain for investigation
  kms_master_key_id         = "alias/aws/sqs"

  tags = {
    Name    = "${var.name_prefix}-pipeline-dlq"
    Purpose = "Failed payment event processing - requires investigation"
  }
}
# Allow Lambda to write failed records / DLQ messages to SQS
resource "aws_iam_role_policy" "pipeline_sqs" {
  name = "${var.name_prefix}-pipeline-sqs"
  role = aws_iam_role.pipeline_processor.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSendToDLQ"
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl"
        ]
        Resource = aws_sqs_queue.pipeline_dlq.arn
      }
    ]
  })
}

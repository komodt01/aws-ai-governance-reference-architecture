# Module: inference
# SageMaker Serverless Inference for payment anomaly detection
#
# FinOps decision: Serverless over dedicated endpoint
# - No idle cost between payment processing windows
# - Cold start acceptable for async anomaly scoring
# - Right-sized memory for fraud model inference
# See ADR-001 for full decision rationale

# IAM role for SageMaker
resource "aws_iam_role" "sagemaker_execution" {
  name = "${var.name_prefix}-sagemaker-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "sagemaker.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "sagemaker_execution" {
  name = "${var.name_prefix}-sagemaker-execution-policy"
  role = aws_iam_role.sagemaker_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${split("/", split("s3://", var.model_s3_uri)[1])[0]}",
          "arn:aws:s3:::${split("/", split("s3://", var.model_s3_uri)[1])[0]}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = var.audit_log_group_arn
      },
      {
        Effect   = "Allow"
        Action   = ["ecr:GetDownloadUrlForLayer", "ecr:BatchGetImage", "ecr:GetAuthorizationToken"]
        Resource = "*"
      }
    ]
  })
}

# SageMaker Model
resource "aws_sagemaker_model" "anomaly_detector" {
  name               = "${var.name_prefix}-anomaly-detector"
  execution_role_arn = aws_iam_role.sagemaker_execution.arn

  primary_container {
    # Use AWS managed XGBoost container - appropriate for tabular anomaly detection
    image          = "683313688378.dkr.ecr.us-east-1.amazonaws.com/sagemaker-xgboost:1.7-1"
    model_data_url = var.model_s3_uri

    environment = {
      SAGEMAKER_PROGRAM          = "inference.py"
      SAGEMAKER_SUBMIT_DIRECTORY = var.model_s3_uri
    }
  }

  tags = {
    Name      = "${var.name_prefix}-anomaly-detector"
    ModelType = "AnomalyDetection"
    UseCase   = "PaymentFraudSignals"
  }
}

# SageMaker Serverless Endpoint Configuration
# Key FinOps parameters: memory_size_in_mb and max_concurrency
resource "aws_sagemaker_endpoint_configuration" "serverless" {
  name = "${var.name_prefix}-serverless-config"

  production_variants {
    variant_name = "primary"
    model_name   = aws_sagemaker_model.anomaly_detector.name

    serverless_config {
      memory_size_in_mb = var.memory_size_mb  # 2048 MB default - tune per model
      max_concurrency   = var.max_concurrency # 10 default - scale per volume
    }
  }

  tags = {
    Name    = "${var.name_prefix}-serverless-config"
    Pattern = "ServerlessInference"
  }
}

# SageMaker Serverless Endpoint
resource "aws_sagemaker_endpoint" "anomaly_detector" {
  name                 = "${var.name_prefix}-anomaly-detector"
  endpoint_config_name = aws_sagemaker_endpoint_configuration.serverless.name

  tags = {
    Name        = "${var.name_prefix}-anomaly-detector"
    CostPattern = "PayPerInference"
  }
}

# Lambda function for inference invocation
# Wraps SageMaker endpoint call with logging and error handling
resource "aws_iam_role" "inference_lambda" {
  name = "${var.name_prefix}-inference-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "inference_lambda" {
  name = "${var.name_prefix}-inference-lambda-policy"
  role = aws_iam_role.inference_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "sagemaker:InvokeEndpoint"
        Resource = aws_sagemaker_endpoint.anomaly_detector.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${var.audit_log_group_arn}:*"
      },
      {
        Effect   = "Allow"
        Action   = ["xray:PutTraceSegments", "xray:PutTelemetryRecords"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_lambda_function" "inference_invoker" {
  function_name = "${var.name_prefix}-inference-invoker"
  role          = aws_iam_role.inference_lambda.arn
  handler       = "index.handler"
  runtime       = "python3.12"
  timeout       = 30
  memory_size   = 256

  filename = "${path.module}/placeholder.zip"

  environment {
    variables = {
      ENDPOINT_NAME = aws_sagemaker_endpoint.anomaly_detector.name
      ENVIRONMENT   = var.environment
    }
  }

  tracing_config {
    mode = "Active"
  }
}
resource "aws_cloudwatch_log_group" "audit" {
  name              = "/aws/lambda/${aws_lambda_function.inference_invoker.function_name}"
  retention_in_days = 30
}

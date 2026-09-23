# ------ KINESIS STREAM POLICY ------

# Account-level resource policy for the payment-event stream.
#
# This resource policy establishes the AWS account as the trusted principal.
# It does not independently restrict access to only the pipeline processor.
# Effective access also depends on IAM identity policies attached to workloads
# and users within the account.
#
# The data-pipeline module separately scopes the pipeline processor role to
# the Kinesis actions required for event consumption.
#
# In a production architecture, producer and consumer identities should be
# explicitly defined and granted only the stream actions required for their
# responsibilities.
resource "aws_kinesis_resource_policy" "pipeline_access" {
  resource_arn = var.kinesis_stream_arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAuthorizedAccountPrincipals"
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

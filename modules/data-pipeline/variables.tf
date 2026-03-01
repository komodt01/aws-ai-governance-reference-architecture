variable "name_prefix" { type = string }
variable "environment" { type = string }
variable "kinesis_shard_count" { type = number }
variable "anomaly_score_threshold" { type = number }
variable "inference_function_arn" { type = string }
variable "bedrock_function_arn" { type = string }

output "kinesis_stream_arn" {
  value = aws_kinesis_stream.payment_events.arn
}

output "kinesis_stream_name" {
  value = aws_kinesis_stream.payment_events.name
}

output "processor_lambda_arn" {
  value = aws_lambda_function.pipeline_processor.arn
}

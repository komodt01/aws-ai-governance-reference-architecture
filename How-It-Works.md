# How It Works — AI Payments Governance Reference Architecture

## Overview

This project demonstrates how security and governance controls can be designed around an AI-enabled payment anomaly detection workflow on AWS.

The architecture separates event ingestion, processing, model inference, generative AI integration, monitoring, and governance into distinct components.

The Terraform provisions the supporting AWS infrastructure. Application handlers and production model artifacts are represented by placeholders where application implementation is outside the scope of the architecture lab.

---

## Processing Flow

The primary architectural flow is:

**Payment Event → Kinesis → Lambda → SageMaker Inference → Risk Evaluation → Monitoring / Escalation**

Amazon Bedrock provides a separate path for AI-assisted exception handling.

Governance and monitoring services surround these processing paths rather than being embedded into a single application component.

---

## 1. Payment Event Ingestion

Amazon Kinesis Data Streams provides the entry point for payment events.

The stream is configured with:

- 24-hour retention
- AWS-managed KMS encryption
- Resource tagging identifying the workload data classification

Kinesis separates event producers from downstream processing and provides the event source for the pipeline-processing Lambda function.

---

## 2. Event Processing

AWS Lambda provides the processing layer for events received from Kinesis.

The Terraform configures the Lambda execution role with permissions required to:

- Read records from Kinesis
- Invoke the inference Lambda
- Invoke the Bedrock gateway Lambda
- Write CloudWatch logs
- Publish X-Ray tracing information

A Kinesis event source mapping connects the stream to the processing function.

### Failure Handling

An Amazon SQS dead-letter queue is configured for failed event processing.

The queue uses KMS-backed encryption and a 14-day message retention period.

This provides a failure path so processing problems can be investigated rather than silently discarded.

---

## 3. Model Inference

The inference module provisions Amazon SageMaker Serverless Inference infrastructure.

The Terraform creates:

- SageMaker execution role
- SageMaker model definition
- Serverless endpoint configuration
- SageMaker endpoint
- Lambda function used to invoke the endpoint
- CloudWatch logging
- X-Ray tracing

Serverless inference was selected to demonstrate an architecture that does not require continuously running inference capacity for an intermittent workload.

Memory and concurrency are configurable so that capacity remains an explicit architecture decision.

### Implementation Scope

The repository provisions the infrastructure required to host and invoke the model.

Production model artifacts and inference application logic are outside the scope of this architecture lab and are represented by placeholders.

The project therefore demonstrates the **inference architecture and control boundaries**, not a completed production anomaly-detection application.

---

## 4. Risk Evaluation

The architecture includes a configurable anomaly threshold.

This represents the point where model output can be evaluated against operational policy.

The intended decision pattern is:

**Model Output → Policy Evaluation → Operational Response**

This distinction is important because a model score is a signal. It does not automatically have to become a business decision.

Thresholds, escalation, and human review can exist between inference and downstream action.

---

## 5. AI-Assisted Exception Handling

Amazon Bedrock is separated from the SageMaker inference path through its own gateway component.

The Bedrock Lambda execution role is scoped for:

- Bedrock model invocation
- DynamoDB result access
- CloudWatch logging
- EventBridge event publishing
- X-Ray tracing

This separation creates an independent control boundary for generative AI functionality.

The Bedrock component is intended to support use cases such as payment exception reasoning, resolution suggestions, and operational assistance without making Bedrock the final business decision authority.

### Implementation Scope

The Terraform provisions the Bedrock gateway infrastructure and required permissions.

The current Lambda handler is a placeholder, so production prompt construction, Bedrock invocation logic, response processing, and application-level audit events would require additional implementation.

---

## 6. Human Escalation Pattern

Amazon EventBridge and Amazon SNS provide the foundation for a human review workflow.

The EventBridge rule looks for a `BedrockRecommendation` event where:

```text
requires_approval = true

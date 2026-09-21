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

The EventBridge rule looks for a `BedrockRecommendation` event where `requires_approval = true`.

Matching events can be routed to the SNS approval-notification topic.

This demonstrates the architectural pattern:

**AI Recommendation → Governance Event → Notification → Human Review**

The project does not implement a production approval application or complete approve/reject workflow.

The EventBridge and SNS resources establish the infrastructure that such a workflow could use.

---

## 7. Monitoring and Audit Infrastructure

Amazon CloudWatch provides the central monitoring layer.

The monitoring module provisions:

- AI audit log group
- Configurable log retention
- Operational alarms
- CloudWatch dashboard
- SNS operational alerts

The dashboard provides visibility into architecture metrics such as:

- Anomaly detection rate
- SageMaker inference latency
- Bedrock gateway invocations
- Kinesis processing lag

CloudWatch alarms also monitor conditions such as SageMaker inference errors and Kinesis iterator age.

---

## 8. AI Results and Governance Data

Amazon DynamoDB provides storage infrastructure for AI scoring results and Bedrock recommendations.

The table includes:

- On-demand capacity
- Server-side encryption
- Point-in-time recovery
- TTL support
- Result-type indexing

Separating results from raw payment data supports a design where governance and operational evidence can be retained without unnecessarily duplicating the original payment payload.

---

## 9. Model Governance

Amazon SageMaker Model Registry provides the foundation for model versioning and approval workflows.

The architecture creates a model package group that can be used as part of a broader model lifecycle process.

Production enforcement of model approval status would require integration with the model deployment pipeline and is outside the scope of this project.

---

## 10. Model Performance Monitoring

The governance module defines a CloudWatch alarm for a custom `ModelPrecision` metric.

The alarm represents a model-performance monitoring pattern where degraded precision can trigger a governance notification.

This can provide an indication that model performance should be investigated.

Automated drift detection, metric publication, and model retraining are not implemented by this architecture and would require additional components.

---

## 11. Identity and Access Control

Major workload components use separate IAM roles rather than sharing a single broad execution identity.

Permissions are scoped around the responsibilities of each component, including:

- Kinesis access
- SageMaker invocation
- Bedrock invocation
- DynamoDB access
- EventBridge publishing
- CloudWatch logging
- X-Ray tracing

This supports least-privilege design and makes service boundaries easier to review.

---

## 12. Infrastructure as Code

Terraform defines the environment through five primary modules:

```text
modules/
├── data-pipeline/
├── inference/
├── bedrock-gateway/
├── monitoring/
└── governance/
```

The root configuration connects these modules through explicit inputs and outputs.

This makes the relationships between architecture components visible in code and allows the infrastructure to be recreated consistently.

---

## Architecture Takeaway

The central lesson of this project is that AI governance is not a control added only to the model.

A governed AI architecture must consider the complete workflow:

**Identity → Data Flow → Inference → Monitoring → Policy → Escalation → Audit**

The model produces information.

The surrounding architecture determines who can access it, how it is monitored, how failures are handled, when human review is introduced, and how evidence is retained.

That surrounding control architecture is the primary focus of this project.

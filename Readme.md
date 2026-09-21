# AI Payments Governance Reference Architecture — AWS + Terraform

## Project Purpose

This project demonstrates an AWS reference architecture for applying security, governance, and operational controls to an AI-enabled payment anomaly detection workflow.

The objective is not simply to deploy an AI model. The architecture explores how an enterprise can place controls around AI inference so that model activity is observable, access is restricted, exceptions can be escalated, and operational decisions remain auditable.

The environment is defined with Terraform and organized into separate modules for data ingestion, inference, AI integration, monitoring, and governance.

---

## Business Scenario

A financial services organization wants to evaluate payment events for potentially anomalous activity while maintaining appropriate security and governance controls around the AI workflow.

The architecture separates several responsibilities:

- Payment event ingestion
- Event processing
- Model inference
- AI-assisted exception handling
- Monitoring and audit logging
- Human escalation
- Model governance

This separation allows security and operational controls to be applied at multiple points rather than treating the AI model as a standalone component.

---

## Architecture Flow

The primary processing path is:

**Payment Event → Kinesis → Lambda → SageMaker Inference → Risk Evaluation → Monitoring / Escalation**

Supporting components provide additional governance and operational capabilities.

### 1. Event Ingestion

Amazon Kinesis Data Streams provides the event-driven entry point for payment events.

### 2. Event Processing

AWS Lambda provides the processing layer between incoming payment events and downstream inference and AI services.

### 3. Model Inference

Amazon SageMaker Serverless Inference provides the infrastructure for anomaly-detection model inference without requiring continuously running inference capacity.

### 4. Risk Evaluation

The architecture provides a configurable anomaly threshold that can be used to determine when additional operational handling is required.

### 5. AI-Assisted Exception Handling

A separate Amazon Bedrock gateway provides the infrastructure for controlled AI-assisted exception handling and operational workflows.

### 6. Monitoring and Auditability

Amazon CloudWatch provides logs, metrics, alarms, and centralized operational visibility across the architecture.

### 7. Governance and Escalation

EventBridge and SNS provide the foundation for routing AI recommendations into human review and notification workflows rather than treating AI output as an automatic final decision.

---

## Security and Governance Controls

The Terraform architecture demonstrates controls relevant to enterprise AI workloads:

- Separate IAM roles for major workload components
- Scoped service permissions
- KMS-backed encryption for supported resources
- Centralized logging and configurable log retention
- CloudWatch metrics and alarms
- SQS dead-letter handling for failed processing
- X-Ray tracing
- Model-performance monitoring
- EventBridge and SNS-based human escalation pattern
- SageMaker Model Registry foundation for model versioning and approval workflows
- Separation between inference, AI integration, monitoring, and governance responsibilities
- Infrastructure defined through Terraform

The intent is to demonstrate that AI governance depends on controls surrounding the model as much as the model itself.

---

## Key AWS Services

| Service | Architectural Role |
|---|---|
| Amazon Kinesis Data Streams | Payment event ingestion |
| AWS Lambda | Event processing and service integration |
| Amazon SageMaker | Serverless inference and model governance foundation |
| Amazon Bedrock | AI-assisted exception-handling integration |
| Amazon CloudWatch | Logging, metrics, alarms, and operational visibility |
| Amazon EventBridge | AI recommendation routing for review workflows |
| Amazon SNS | Operational alerts and approval notifications |
| Amazon SQS | Dead-letter handling |
| Amazon DynamoDB | AI scoring and recommendation result storage |
| AWS IAM | Workload identity and scoped authorization |
| AWS KMS | Encryption controls |
| AWS X-Ray | Distributed tracing |

---

## Terraform Structure

The root Terraform configuration coordinates five primary architecture modules:

```text
modules/
├── data-pipeline/
├── inference/
├── bedrock-gateway/
├── monitoring/
└── governance/

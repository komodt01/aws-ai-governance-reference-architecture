# AI Payments Reference Architecture (AWS + Terraform)

## Overview

This project implements a secure, event-driven AI inference pipeline using AWS services and Terraform. The architecture demonstrates how to design a governed AI system with monitoring, approval controls, audit logging, and least-privilege IAM.

The solution simulates a financial payment anomaly detection workflow.

---

## Architecture Summary

Flow:

1. Kinesis stream ingests payment events.
2. Lambda (pipeline processor) consumes events.
3. Events are passed to a SageMaker Serverless endpoint.
4. Anomaly scores are evaluated.
5. High-risk events trigger governance workflows.
6. SNS alerts notify operations teams.
7. CloudWatch logs, metric filters, and alarms provide observability.

---

## Key AWS Services

- Amazon Kinesis Data Streams
- AWS Lambda
- Amazon SageMaker Serverless Inference
- Amazon SNS
- Amazon CloudWatch (Logs, Metrics, Alarms, Dashboards)
- AWS IAM (least privilege roles)
- AWS KMS (encryption)
- Amazon SQS (DLQ)

---

## Security Controls Implemented

- IAM role separation per component
- DLQ for failed processing
- KMS encryption for SNS
- Audit log retention controls
- CloudWatch anomaly detection metrics
- Explicit metric alarms for inference errors
- Governance approval topic for human override
- Terraform state isolation (no credentials in repo)

---

## Repository Structure

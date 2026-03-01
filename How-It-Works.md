
---

# 2️⃣ architecture.md (How It Works Deep Dive)

Create: `architecture.md`

```markdown
# Architecture Deep Dive

## Data Flow

Payment Event → Kinesis → Lambda → SageMaker → CloudWatch → SNS → Ops

---

## Step 1: Ingestion

Kinesis Data Stream ingests simulated payment events. This supports real-time streaming architecture patterns common in financial systems.

---

## Step 2: Event Processing

Lambda function:
- Pulls records from Kinesis
- Parses payment payload
- Sends inference request to SageMaker endpoint
- Evaluates anomaly score threshold
- Publishes to SNS if threshold exceeded

DLQ is configured for failed processing.

---

## Step 3: Inference Layer

SageMaker Serverless endpoint:
- Hosts anomaly detection model
- Auto-scales based on request volume
- Emits CloudWatch metrics

---

## Step 4: Governance Layer

SNS Topic:
- Receives anomaly alerts
- Can be integrated with approval workflows
- Human override capability modeled

CloudWatch Log Metric Filters:
- Bedrock invocations
- Human override events
- Anomaly flags

---

## Step 5: Monitoring & Observability

CloudWatch Alarms:
- Inference errors
- Kinesis iterator age
- High anomaly rate

CloudWatch Dashboard:
- Centralized operational visibility

---

## Security Architecture

- IAM roles scoped per module
- No hardcoded credentials
- KMS encryption on SNS
- Explicit log retention policies
- Separate execution roles for Lambda and SageMaker

---

## Design Principles

- Event-driven
- Least privilege
- Observability first
- Governance-aware AI
- Infrastructure as Code

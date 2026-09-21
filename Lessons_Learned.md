# Lessons Learned

This project reinforced both Terraform implementation details and broader architecture lessons for building governed AI workloads on AWS.

---

## 1. IAM Resources Require the Correct Identifier

AWS resources do not always accept interchangeable IAM identifiers.

For the Lambda `role` attribute, Terraform requires the IAM role ARN rather than the role ID.

```hcl
# Incorrect
role = aws_iam_role.pipeline_processor.id

# Correct
role = aws_iam_role.pipeline_processor.arn
```

### Lesson

Understanding the relationship between AWS resource identifiers — names, IDs, and ARNs — is important when connecting services through Infrastructure as Code.

---

## 2. Terraform Module Outputs Define Integration Boundaries

Resources inside one Terraform module are not automatically available to another module.

When the root configuration or another module requires a value, that value must be explicitly exported.

For example:

```hcl
output "audit_log_group_name" {
  value = aws_cloudwatch_log_group.example.name
}
```

### Lesson

Terraform outputs function as interfaces between infrastructure modules.

This makes module design an architecture concern, not simply a Terraform syntax concern.

---

## 3. Resource Constraints Matter During Automation

AWS services can impose validation rules that are easy to overlook when infrastructure is created manually.

During implementation, SNS tag values required adjustment because certain characters were not accepted.

### Lesson

Infrastructure as Code exposes configuration constraints early and makes them reproducible.

A configuration that appears architecturally valid must still satisfy the implementation requirements of the underlying cloud service.

---

## 4. Event Source Relationships Must Be Explicit

Lambda event source mappings require the correct function and event source identifiers.

During implementation, it was important to distinguish between the Lambda function identifier and the Kinesis stream ARN when validating the integration.

### Lesson

Event-driven architectures depend on clearly defined relationships between producers, event sources, processors, and downstream services.

Misidentifying one side of that relationship can prevent the workflow from operating even when the individual resources are deployed correctly.

---

## 5. Terraform State and Application Code Serve Different Purposes

Terraform manages infrastructure state. It does not replace source control for application or model code.

Destroying Terraform-managed infrastructure removes managed cloud resources but does not remove the project source stored in version control.

### Lesson

Infrastructure lifecycle and application lifecycle should be treated as related but separate concerns.

Version control remains the source of truth for the code and configuration used to recreate the environment.

---

## 6. AI Governance Depends on Observability

A model cannot be meaningfully governed if its activity and surrounding workflow cannot be observed.

The project reinforced the importance of:

* Explicit logging
* Defined retention
* Metric filters
* Alert thresholds
* Failure visibility
* Human escalation paths

### Lesson

Observability is not only an operational capability for AI systems. It also provides evidence needed for security oversight, incident investigation, and governance.

---

## 7. Model Output and Business Decisions Should Remain Separate

An anomaly score is a signal produced by a model. It does not automatically have to become the final operational decision.

### Lesson

A governed architecture should distinguish between:

**Model Output → Policy Evaluation → Operational Action**

This creates opportunities for thresholds, escalation, human review, and other controls between inference and action.

---

## 8. Serverless Inference Introduces a Cost and Capacity Tradeoff

SageMaker Serverless Inference reduces the need to maintain continuously running inference capacity.

That can be useful for intermittent workloads, but serverless architecture does not eliminate capacity planning.

Concurrency, latency, request patterns, and workload volume still matter.

### Lesson

Cost optimization should be treated as an architecture decision with operational tradeoffs rather than simply choosing the lowest-idle-cost service.

---

## 9. AI Components Benefit From Separate Control Boundaries

The architecture separates anomaly detection inference from the Amazon Bedrock integration.

### Lesson

Different AI capabilities can introduce different risks, permissions, monitoring requirements, and operational purposes.

Separating those capabilities makes it easier to apply workload-specific IAM, logging, monitoring, and governance controls.

---

## 10. Governance Is an Architecture Property

The most important lesson from the project is that AI governance cannot be added only at the model layer.

Governance depends on the surrounding architecture:

**Identity → Data Flow → Inference → Monitoring → Policy → Escalation → Audit**

The AI model is one component of the system. The surrounding controls determine how the model is accessed, observed, evaluated, and incorporated into business processes.

# Lessons Learned

## 1. IAM ARN vs ID

Lambda "role" attribute must reference role ARN, not role ID.

Incorrect:
role = aws_iam_role.pipeline_processor.id

Correct:
role = aws_iam_role.pipeline_processor.arn

---

## 2. Terraform Module Outputs Matter

If referencing module attributes:
Ensure the attribute is exported in outputs.tf.

Missing output:
module.inference.audit_log_group_name

Requires:
output "audit_log_group_name" { ... }

---

## 3. SNS Tag Restrictions

SNS tags reject certain characters.
Avoid special characters like "/" in tag values.

---

## 4. Event Source Mapping Validation

Lambda event source mapping requires function name or ARN.
Do not pass Kinesis ARN to get-function.

---

## 5. Terraform State Does Not Store Code

Destroying infrastructure does NOT remove code.
Version control is essential for incremental tracking.

---

## 6. Governance Requires Observability

AI systems require:
- Explicit logging
- Metric filters
- Alert thresholds
- Human escalation path

---

## 7. Serverless Tradeoffs

SageMaker Serverless reduces idle cost but requires careful concurrency tuning.

# Teardown Guide

To prevent ongoing AWS costs:

## Destroy All Infrastructure

terraform destroy

---

## Verify Destruction

Check for:

aws kinesis list-streams
aws lambda list-functions
aws sagemaker list-endpoints
aws sns list-topics
aws logs describe-log-groups

All relevant resources should be removed.

---

## Optional Manual Cleanup

If needed:

aws sagemaker delete-endpoint --endpoint-name <name>
aws sagemaker delete-model --model-name <name>

---

## Cost-Sensitive Services

- SageMaker Endpoint (most expensive)
- Kinesis shards
- Lambda invocations
- CloudWatch custom metrics
- SNS messages

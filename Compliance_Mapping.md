# Compliance Mapping

## NIST 800-53

AC-6 – Least Privilege  
Implemented via scoped IAM roles per service.

AU-2 – Audit Events  
CloudWatch logging enabled for Lambda and SageMaker.

AU-6 – Audit Review  
Metric filters and alarms for anomaly tracking.

SI-4 – System Monitoring  
CloudWatch alarms and dashboards implemented.

SC-13 – Cryptographic Protection  
KMS encryption for SNS topics.

RA-5 – Risk Assessment  
Anomaly detection model integrated into processing pipeline.

---

## ISO 27001

A.9 – Access Control  
Role-based IAM separation.

A.12 – Operations Security  
Monitoring and alerting configured.

A.16 – Incident Management  
SNS alerts simulate escalation workflow.

# Trust Boundaries — AI Payments Governance Reference Architecture

## Follow the Decision, Not Just the Model

The security boundary in an AI-enabled payment workflow is not limited to the point where a model is invoked.

A payment event moves through several systems, identities, and decision points before it can influence an operational response.

In this architecture, the important path is:

```text
Payment Event
    ↓
Event Processing
    ↓
Model Inference
    ↓
Risk Signal
    ↓
Policy Evaluation
    ↓
AI-Assisted Recommendation
    ↓
Human / Operational Decision
    ↓
Audit Evidence
```

Each transition changes either the data being trusted, the identity acting on it, or the authority associated with the result.

The model is one participant in that chain.

It is not the security boundary for the entire workflow.

---

## A Payment Event Starts as Input, Not Truth

Amazon Kinesis provides the entry point for payment events.

Once an event enters the pipeline, downstream components may use its contents to invoke inference, evaluate risk, or initiate additional processing.

That makes the integrity and origin of the event important.

The architecture should not assume that data is trustworthy merely because it reached Kinesis.

In a production system, questions would include:

- Which systems are authorized to publish payment events?
- How is the producer authenticated?
- What prevents an unauthorized producer from submitting events?
- How is malformed or unexpected data handled?
- Which fields are required before inference occurs?
- Does the event contain sensitive payment or customer information?
- How much of that information actually needs to reach downstream AI components?

The implemented Terraform establishes the stream and processing infrastructure.

Production event validation, producer authentication design, and application-level data validation require additional implementation.

---

## Processing Identity Determines What the Workflow Can Reach

The Lambda processing layer is not merely moving data.

Its execution identity determines which downstream services the workflow can invoke.

The processing function is permitted to interact with resources required for its role, including the inference and Bedrock gateway functions.

That creates a workload-identity boundary.

A compromised processing function should not automatically receive administrative authority over SageMaker, Bedrock, monitoring, governance, or unrelated AWS resources.

Separate IAM roles help constrain that authority.

The architectural question is therefore not only:

**Can this Lambda call the next service?**

It is also:

**What else could this identity reach if the processing component were compromised?**

Least privilege reduces the consequences of crossing that boundary.

---

## Inference Produces a Signal

The SageMaker path changes the nature of the information moving through the architecture.

Before inference, the workflow contains payment-event data.

After inference, it also contains a model-produced assessment.

That assessment may be useful.

It is not automatically authoritative.

The architecture treats the model output as a risk signal that can be evaluated against operational policy.

```text
Payment Data → Model → Risk Signal
```

should not silently become:

```text
Payment Data → Model → Final Business Decision
```

The distinction matters because model output can be wrong, incomplete, degraded, or affected by changes in input data.

The model is trusted to perform inference within its defined purpose.

It is not inherently trusted to determine the organization's final response.

---

## The Threshold Is a Policy Boundary

The configurable anomaly threshold represents more than a technical parameter.

It influences when model output is considered significant enough to trigger additional handling.

Changing that threshold can therefore change operational behavior without changing the model itself.

A production architecture should treat material threshold changes as governed configuration.

Relevant questions include:

- Who can change the threshold?
- Is the change reviewed?
- Is the previous value retained?
- Can the organization determine which threshold was active for a historical decision?
- Does a threshold change require testing before production use?
- What happens when model behavior changes but the threshold does not?

This is an example of AI governance existing outside the model artifact.

The model can remain unchanged while the organization's interpretation of its output changes.

---

## Bedrock Introduces a Different Kind of Trust

The Bedrock gateway represents a separate generative AI capability.

Its intended purpose is AI-assisted exception handling and operational support.

This is different from the anomaly-detection inference path.

A generative model may produce explanations, recommendations, or suggested actions that are useful to an operator.

Those outputs should still be treated as generated content rather than trusted instructions.

The architecture therefore separates:

**AI recommendation**

from

**business authorization.**

The current Terraform provisions the Bedrock gateway infrastructure and permissions, while production prompt construction, model invocation logic, response processing, and application-level audit events are outside the implemented scope.

That distinction is important because the security properties of a generative AI workflow depend heavily on logic that surrounds the model invocation.

---

## Prompt and Context Become Security-Relevant Data

Once production Bedrock logic is introduced, the prompt and any supplied context become part of the trust model.

A future implementation would need to determine:

- Which payment information can be included in prompts.
- Whether sensitive data should be removed or minimized.
- Which systems are allowed to provide contextual information.
- Whether user-controlled content can influence the prompt.
- How prompt injection or malicious context is handled.
- Whether model responses can introduce untrusted instructions.
- What prompt and response evidence should be retained.
- How retention requirements interact with sensitive financial data.

The current repository does not implement these controls because the Bedrock handler is represented by placeholder application logic.

They are nevertheless important boundaries for a production version of the architecture.

---

## A Recommendation Does Not Carry Approval Authority

The EventBridge and SNS pattern establishes a useful separation.

A Bedrock recommendation requiring approval can generate a governance event and notification.

That creates the pattern:

```text
AI Recommendation
       ↓
Governance Event
       ↓
Human Notification
       ↓
Human / Operational Review
```

The AI component can recommend.

It does not thereby receive authority to approve its own recommendation.

The current project establishes infrastructure supporting escalation but does not implement a complete approve/reject application.

A production workflow would need to establish who is authorized to approve different actions and how that approval is authenticated and recorded.

For higher-impact actions, the approval boundary may need to consider transaction value, data sensitivity, regulatory requirements, or the consequence of an incorrect decision.

---

## Human Review Is a Control Only If the Human Has Useful Information

Adding a person to a workflow does not automatically make the workflow governed.

A reviewer needs enough information to understand what is being approved.

Depending on the use case, that could include:

- The relevant payment context.
- The model score.
- The threshold that triggered escalation.
- The AI-generated recommendation.
- Relevant supporting evidence.
- Known limitations.
- Previous related activity.
- The action that approval will authorize.

Otherwise, a human approval step can become little more than confirmation of an AI recommendation.

The architecture should preserve meaningful human authority rather than creating a ceremonial approval step.

---

## Model Artifacts Have Their Own Trust Boundary

The architecture includes a SageMaker Model Registry foundation for model versioning and approval workflows.

That introduces another question:

**Which model is trusted to run?**

A production model lifecycle may include training, evaluation, registration, approval, deployment, monitoring, replacement, and retirement.

Those stages should not collapse into one unrestricted administrative process.

A model artifact being technically deployable does not necessarily mean it has been approved for production use.

Likewise, registering a model does not prove that deployment enforcement exists.

The current project creates the Model Registry foundation.

Production enforcement of approved model status in the deployment pipeline is outside the implemented scope.

---

## Infrastructure Authority Can Change AI Behavior

Terraform defines much of the surrounding control architecture.

An actor capable of modifying and applying the infrastructure may be able to change:

- IAM permissions.
- Model endpoint configuration.
- Bedrock access.
- Logging.
- Alarm thresholds.
- Event routing.
- Data retention.
- Encryption configuration.
- Governance resources.

Infrastructure administration is therefore part of the AI trust model.

AI governance would be incomplete if model access were tightly controlled while the infrastructure defining those controls could be changed without appropriate review.

Production use should consider protections around source control, Terraform execution, state, deployment credentials, approvals, and security-sensitive changes.

---

## Monitoring Is Evidence, Not Authority

CloudWatch, X-Ray, alarms, and governance notifications provide visibility into the workflow.

They help answer questions such as:

- Did processing occur?
- Was inference invoked?
- Did an error occur?
- Was processing delayed?
- Did a governance event fire?
- Is model performance degrading?

Monitoring does not itself determine whether a business decision was correct.

It provides evidence that can be used to investigate behavior and evaluate whether controls operated as intended.

That distinction is particularly important for AI systems because operational health and decision quality are different measurements.

A model endpoint can be technically healthy while producing poor results.

---

## Failure Changes the Decision Path

An AI workflow needs defined behavior when one of its components is unavailable or produces an unexpected result.

The architecture includes dead-letter handling, alarms, and escalation foundations, but production behavior still needs business decisions around failure.

Examples include:

**Kinesis processing fails**  
Should the payment wait, retry, or follow another processing path?

**SageMaker inference fails**  
Should the transaction continue without a score, stop, or require manual review?

**Bedrock is unavailable**  
Can exception handling continue without AI assistance?

**Monitoring fails**  
Can the workflow continue when evidence cannot be recorded?

**Human approval is unavailable**  
Does the request wait, expire, escalate, or follow an emergency process?

These are not simply availability questions.

They determine whether the architecture fails open, fails closed, or degrades into another controlled operating mode.

---

## The Evidence Must Reconstruct the Decision

For a governed AI workflow, it should eventually be possible to reconstruct why an important operational action occurred.

That may require connecting evidence across multiple components:

```text
Payment Event
    ↓
Processing Identity
    ↓
Model Version
    ↓
Model Output
    ↓
Policy / Threshold
    ↓
AI Recommendation
    ↓
Human Decision
    ↓
Operational Action
```

Not every field needs to be stored forever, especially where payment or customer data is sensitive.

But the organization needs enough evidence to understand which identities, model versions, policies, recommendations, and approvals contributed to a material decision.

Auditability is therefore a property of the workflow, not just a log group.

---

## Where Authority Actually Lives

This architecture deliberately distributes authority.

Kinesis accepts events.

Lambda processes them.

SageMaker produces inference.

Bedrock can provide AI-assisted recommendations.

Policy determines when results require additional handling.

EventBridge and SNS support escalation.

Humans or operational systems ultimately determine authorized business action.

CloudWatch and related services retain operational evidence.

The security objective is to prevent those responsibilities from collapsing into:

```text
AI Produced Output → Action Automatically Trusted
```

The stronger architecture preserves the distinction:

```text
Data
  ↓
Processing
  ↓
Inference
  ↓
Signal
  ↓
Policy
  ↓
Recommendation
  ↓
Authorized Decision
  ↓
Evidence
```

The model is allowed to influence a decision.

It is not automatically granted the authority to make that decision.

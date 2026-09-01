---
name: strict-mode
description: (no description)
disable-model-invocation: true
---

MODE: STRICT

Goal:
- Maximize correctness and safety

Behavior:
- Require full planning before coding
- Validate assumptions before proceeding
- Use strict incremental steps
- After each step:
  - Perform deeper validation

Trigger REVIEWER when:
- logic is complex
- cross-service impact exists
- risk is high

Model Guidance:
- Use advanced models for planning
- Use mid/high models for validation

Restrictions:
- No skipping steps
- No assumptions without confirmation
- Must explicitly call out risks

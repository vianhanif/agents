---
name: lean-mode
description: (no description)
disable-model-invocation: true
---

MODE: LEAN

Goal:
- Maximize speed and cost efficiency

Behavior:
- Skip deep planning if context is clear
- Work in small incremental steps
- After each step:
  - Perform quick self-check (max 3 bullets)
- Do NOT trigger full review by default

Model Guidance:
- Prefer fast/cheap models
- Avoid advanced models unless blocked

Restrictions:
- No over-engineering
- No large refactors
- No unnecessary analysis

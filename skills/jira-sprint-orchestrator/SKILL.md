---
name: jira-sprint-orchestrator
description: Automates the triage and orchestration of non-bug sprint tasks (features, chores, refactors).
---

# /jira-sprint-orchestrator

## Overview
Automates the triage and orchestration of non-bug tasks (features, chores, refactors) from a sprint document.

## Usage
Run `/jira-sprint-orchestrator <path-to-sprint-md-file>`

## Logic
1. **Parse**: Reads the specified markdown file for Jira ticket sections.
2. **Filter**: Identifies non-bug tasks (exclude Jam evidence links).
3. **Delegate**: For every identified task, launches an independent `@coder` or `@planner` child agent.
4. **Conventions**:
    - **Docs**: Evaluation docs stored in `$(dirname <sprint-file>)/notes/` using format `{YYYYMMDD}-{ticket-id}-{slug}.md`.
    - **Scope**: All activity strictly confined to user's local `work/gitlab/` directory.

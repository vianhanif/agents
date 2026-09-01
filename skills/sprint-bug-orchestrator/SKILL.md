# /sprint-bug-orchestrator

## Overview
Automates the triage and orchestration of BUG tickets from a sprint document. Filters for tickets that explicitly contain Jam evidence links (jam.dev). For non-bug sprint tasks (features, chores, refactors), use `/jira-sprint-orchestrator` instead.

## Usage
Run `/sprint-bug-orchestrator <path-to-sprint-md-file>`

## Logic
1. **Parse**: Reads the specified markdown file for Jira ticket sections.
2. **Filter**: Identifies tickets containing `https://jam.dev/c/` URLs.
3. **Delegate**: For every identified ticket, launches an independent `@analyzer` child agent.
4. **Enforced Conventions**:
    - **Docs**: Evaluation docs must be stored in `$(dirname <sprint-file>)/notes/` using format `{YYYYMMDD}-{ticket-id}-{slug}.md`.
    - **Halt**: Agents MUST halt after Phase 1 (Evaluation) and wait for user's "begin" command to move to fix planning.
    - **Scope**: All activity strictly confined to user's local `work/gitlab/` directory.

## Workflow Discipline
- **Project Root**: Detects from git root for each ticket's identified service repository.
- **Independence**: Each ticket agent runs in its own process.
- **Approval**: No file edits or state-changing commands without explicit user approval.
- **Reporting**: Agent reports to parent orchestrator with: `ticket-id`, `evaluation-doc-path`, `root-cause-summary`, and `repo-status`.

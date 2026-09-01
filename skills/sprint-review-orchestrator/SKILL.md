# /sprint-review-orchestrator

## Overview
Automates the triage and orchestration of team merge requests (MRs) listed in a sprint or review document.

## Usage
Run `/sprint-review-orchestrator <path-to-mr-list-file>`

## Logic
1. **Parse**: Reads the specified markdown file for MR/ticket sections.
2. **Filter**: Dedupes MRs, checks review status via `glab` or `git-review-cli`.
3. **Delegate**: For every pending MR, launches an independent `@reviewer` child agent.
4. **Phase 4: Comment Posting**: After findings are surfaced and triaged:
    - Findings are categorized (Ignore/Expected, Future Task, Ask Confirmation, Request Fix, Approve).
    - Construct per-MR note comments via `glab mr note <iid> --repo <group/repo> -m "<comment-text>"`.
    - Report note URLs per finding to the orchestrator.
5. **Enforced Conventions**:
    - **Docs**: Evaluation docs must be stored in `$(dirname <sprint-file>)/../notes/{YYYYMMDD}-{ticket-id}-{slug}.md` or standard `work/gitlab/sprints/{Sprint Name}/{YYYYMMDD}-{ticket-id}-{slug}.md`.
    - **Halt**: Agents MUST halt after Phase 3 (Surface) and wait for user approval before *posting* any comments to the MR platform.
    - **Scope**: Review only. No code edits, no branch management, no MR merges.

## Workflow Discipline
- **Project Root**: Detects from git root for each MR's identified service repository.
- **Independence**: Each MR agent runs in its own process.
- **Approval**: No file edits or comment posting without explicit user approval.
- **Reporting**: Agent reports to parent orchestrator with: `MR-ID`, `review-doc-path`, `risk-level`, and `summary-findings`.

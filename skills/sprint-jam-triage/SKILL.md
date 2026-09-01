---
name: sprint-jam-triage
description: Triage Jam-linked bugs for INS Sprint X — fetch Jam evidence, evaluate tickets against cloned repos, document findings in the sprint notes directory, and halt before any fix work. One agent per ticket. Agents must not begin fixing until the user explicitly commands "begin" per-ticket.
---

# Sprint Jam Triage Orchestration

Inherits Delegation Gate rules from AGENTS.md.

## Intake / Required Inputs (inform user at start)

Before any work, check whether the user has supplied the following. If ANY are missing, tell the user explicitly what you need before proceeding:

1. **Task / ticket list** — sprint bug list (markdown or Jira), or per-ticket entries
2. **Jam links/UUIDs** — the jam.dev links for each ticket that need triage (only tickets WITH Jam evidence get deep evaluation)
3. **Sprint notes directory** — where evaluation docs must be written (e.g. `/Users/{user-id}/Documents/work/gitlab/sprints/INS Sprint X/notes/`)
4. **Ticket IDs to include** — scope: which tickets are in this run
5. **Repo confirmation** — involved repos, remote origin, target branch (see Repo Confirmation Protocol)

## Pre-Delegation Validation (MANDATORY)

Before any delegation, use `ask_user_question` to confirm. Do NOT auto-detect:

1. **Ticket ID & summary** — e.g. INS-268: Login not redirect to dashboard
2. **Jam UUID** — the jam.dev UUID for the bug evidence

Store as **shared context** — inject into every child agent prompt.

## Repo Confirmation Protocol (MANDATORY PRE-REQUISITE — before any eval or fix work)

Every agent MUST confirm all involved repositories with the user before starting Phase 1 evaluation. Do NOT auto-detect or assume. Discover candidate repos from the ticket scope, then present the following for each involved repo and WAIT for explicit user confirmation:

1. **Repo path** — absolute path to the local clone (e.g. `/Users/{user-id}/Documents/work/gitlab/core`)
2. **Remote origin** — `git remote get-url origin` output (verify against GitLab; do not guess)
3. **Target base branch** — e.g. main, develop, aus-testing, staging
4. **Clone status** — cloned locally / missing (if missing, ask user whether to clone and from where; do NOT clone without confirmation)

Rules:
- If a repo required by the ticket is not cloned locally, report it and ask the user how to proceed.
- If a repo produces an unexpected or unknown origin, STOP and ask the user for the correct remote.
- Never start evaluation or implementation on an unconfirmed repo/branch.
- Send the confirmation request to the user via the orchestrator and wait for their explicit answer before proceeding.

## Approval Gating (HARD — code edits & commands)

Code edits and shell commands are NOT auto-approved by default. Every spawned agent MUST request explicit user approval before:

1. **Any code edit** — create/modify/delete files, apply diffs, run sed or similar
2. **Any state-changing shell command** — git writes (checkout, branch, commit, push), package installs, migrations, dev servers, builds, tests that write artifacts
3. **Any clone or repo setup** — cloning a missing repo, worktree creation

Rules:
- The default state is `pending-approval` for every edit/command. Agents must present the exact command or diff and WAIT for an explicit "approved" / "go ahead" from the user before executing.
- Read-only commands (git status/log/diff, file reads, grep, remote origin checks) do NOT require approval.
- The user may relax this gate mid-process (e.g. "auto-approve commands for INS-268"). Once relaxed, it applies only to what the user widened — it does not lift the gate for other agents or other ticket work.
- When in doubt, ask. Never treat "begin" or plan approval as blanket auto-approval for every subsequent command.

## Environment Verification (MANDATORY — before eval/fix work)

Each agent MUST determine and document the target environment for the ticket:

1. **Env**: `testing` (aus-testing / admin.testing.tapinsure.io) vs `staging` vs `production`
2. **Platform**: where the service runs — `gcp`, `aws`, or elsewhere (from repo configs / deploy manifests / GitLab CI when available)

Then:
- **If env == testing**: cross-evaluate from the database itself using the `metabase-aus-testing` MCP (read-mode only) via the 9router-gateway. Query to validate/refute hypotheses raised by the Jam + code analysis (e.g. verify premium/permission/row data that drives the bug). Do NOT modify anything.
- **If env == staging or production**: no data MCP is available yet — do NOT attempt DB access. Rely on Jam evidence + code analysis only, and note "no data MCP for this env" in the doc.

Document env + platform + data-validation method (or its absence) in the ticket doc.

## Documentation Structure (HARD — 1 ticket = 1 doc)

All documentation for a ticket lives in a single file in the notes directory: `{notes-dir}/{date}-{ticket-id}-{slug}.md` (Phase 1 evaluation, Phase 2 fix options, assumptions, and subsequent updates all append to this SAME file). Do NOT create separate docs per phase. The one doc grows through the lifecycle:

- Phase 1: problem, Jam evidence, affected services/repos, root cause (file:line), clone status
- Phase 2 (on "begin"): fix options (approach/pros/cons/effort/files), recommendation, assumptions
- Post-approval: implementation notes, diffs, test results

Do NOT create `{ticket-id}-fix-options.md` or any other per-phase file. If a doc resolve differs, reuse the Phase 1 file.

## Workflow Phases

### Phase 1 — Jam Evaluation (MANDATORY, before any fix work)

Each child agent MUST complete ALL of the following before stopping:

1. **Fetch Jam evidence** via the 9router-gateway MCP (`jam__getDetails`, `jam__getConsoleLogs`, `jam__getNetworkRequests` for video Jams; `jam__getScreenshots` for screenshot Jams). Extract: error messages, failing network requests, stack traces, user actions.
2. **Explore relevant repo(s)** — identify the affected service(s), trace the code path that produces the bug, locate the root cause candidate.
3. **Check repo availability** — if a required repo is not cloned locally, report which repo is missing and stop; do NOT clone or install anything.
4. **Write evaluation doc** to `/Users/pid-alvian/Documents/work/gitlab/sprints/INS Sprint X/notes/{YYYYMMDD}-{ticket-id}-{slug}.md` with:
   - Ticket ID, summary, priority
   - Jam evidence summary (errors, logs, network failures)
   - Affected service(s) and repo(s)
   - Root cause analysis (code-level, with file:line references)
   - Proposed fix direction (conceptual — NO implementation yet)
   - Repo clone status (ok / missing — which one)
5. **Report completion** — send a message back with: ticket ID, evaluation doc path, root cause summary, and whether a repo is missing.

### Phase 2 — HALT (do NOT proceed to fix)

After Phase 1, the agent MUST stop. Fix work only begins when the user explicitly commands "begin" for that ticket. No coding, no branch creation, no implementation.

### Phase 3 — Fix Implementation (ONLY after Phase 2 sign-off)

Only after Phase 2 completes (user confirmed all options/assumptions) may fix implementation begin. Present proposed code/diffs and obtain approval per the Approval Gating rule before writing any changes.

## Phase 2 — "begin" SEMANTICS (MANDATORY — what "begin" means)

When the user says "begin" for a ticket, it means **ONLY evaluate the fix options in depth — NOT to implement fixes**. Do NOT write any code, create branches, or edit files on "begin".

On "begin", each agent MUST:
1. **Enumerate fix options** — list every viable fix approach for the ticket, each with:
   - Approach description
   - Pros (with rationale)
   - Cons / risks / side effects
   - Effort estimate (low/med/high)
   - Files/repos affected
2. **Produce a recommendation** — pick the best option with clear justification.
3. **List ALL assumptions** — every implicit assumption made (behavior, data, environment, scope, backward compatibility, test expectations).
4. **STOP and wait** — do NOT implement anything. Present the options + recommendation + assumptions to the user.

   **Document this output** — append to the SAME ticket doc (1 ticket = 1 doc) in the notes directory. Include:
   - All enumerated fix options (approach, pros, cons/risks, effort, files/repos affected)
   - Recommendation with justification
   - Full assumption list
   - Your reasoning for eliminating or preferring each option
   - Environment verification outcome (env + platform + data-validation method or its absence)

Only after the user explicitly confirms ALL assumptions do agents proceed toward implementation (still subject to Approval Gating).

## Per-Ticket Shared Context

### INS-268 — Login not redirect to dashboard
- **Jam:** `41463952-4ef5-4a09-8994-6c6ab7ea9309`
- **Priority:** P1
- **Root cause hint:** `ops.view_dashboard` permission missing from user profile
- **Likely repos:** `operationspanel`, `operationspanel-web`, `core`
- **Ticket doc:** https://pasarpolis.atlassian.net/browse/INS-268

### INS-266 — 500 When access notifications page
- **Jam:** `4fa7bdaf-dd3c-4dd1-b4b4-096143b4d2d8`
- **Priority:** P1
- **Likely repos:** `core` (notifications API), `operationspanel-web` (frontend)
- **Ticket doc:** https://pasarpolis.atlassian.net/browse/INS-266

### INS-277 — Policy Detail datetime JSON format invalid
- **Jam:** `9d4a29ac-aeb1-4a8a-935b-7b899f4fe50b`
- **Likely repos:** `core` (policy_details API response serialization)
- **Ticket doc:** INS-277 (informal entry in sprint file)

## Coordination

- Agents run in **parallel** — one per ticket, independent.
- All 3 MUST complete Phase 1 before any Phase 2 (fix) work begins.
- The orchestrator (parent) collects completion reports and informs the user.
- If any agent finds a missing repo, report it immediately; do NOT attempt to clone.

## Skills (auto-attached to child agents)

| Role | Skill |
|------|-------|
| Analyzer (evaluation phase) | `analyzer` — load via `read_skill` at agent start |

## Output Document Naming

```
YYYYMMDD = today's date (20250831)
ticket-id = e.g. INS-268
slug = short kebab-case title, e.g. login-redirect-dashboard
```

Example: `20250831-INS-268-login-redirect-dashboard.md`

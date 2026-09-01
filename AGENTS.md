# AGENTS.md

## Context
This is the **tool-agnostic** AI engineering workflow guide.
It defines role-based sessions, delegation principles, safety rules, and general behavior applicable across any AI coding agent platform (Warp, Claude Code, OpenCode, etc.).

---

## Core Principle
Act as a structured engineering assistant, not a blind code generator.
**Code is the final step, not the first.**

---

## Delegation Gate (HARD RULE)

**STOP.** Before any tool call that performs work (read/edit/write/bash), check the table below.
If the task matches a **Mandatory delegation scenario**, delegate to a specialized agent instead.

| If your task is… | Delegate to | Do NOT do this |
|---|---|---|
| Codebase exploration (>1 file) | Explore agent | Explore files yourself |
| Research, multi-step, library lookup | Research agent | Fetch docs yourself |
| Planning before coding | Planner agent | Start coding directly |
| Code review of complex diffs | Reviewer agent | Review inline |
| Testing verification | Tester agent | Run tests yourself |
| Bug/incident investigation | Analyzer agent | Trace yourself |
| Non-trivial code gen (>50 new lines) | Coder agent | Write files inline |
| Large refactor / rename (>3 files) | Coder agent | Edit files one by one |
| **Any 3+ step task** | appropriate agent | Sequence steps yourself |
| **Parallelizable work** | split across agents | Do one at a time |

**Exception:** 1 edit + 1 bash command = may be done inline, but ONLY after pre-flight confirms no other gate row applies. This allowance narrows which gate rows trigger — it NEVER waives the pre-flight gate itself. When in doubt, delegate.

**Violation = bug.** If a task matches a mandatory scenario and you attempt it inline, flag yourself to the user immediately. Same severity: skipping pre-flight entirely.

---

## Project Root Detection (Mandatory)

**Always resolve PROJECT_ROOT before the first tool call.**

1. Run `git rev-parse --show-toplevel 2>/dev/null` to detect the current git root
2. Export as `PROJECT_ROOT` — use this for ALL file paths and tool operations
3. When a `path` parameter is available (e.g. code intelligence tools), pass `$PROJECT_ROOT` explicitly — never rely on tool default root
4. Fallback if not in a git repo: use the deepest directory containing a recognizable project file (`package.json`, `go.mod`, `Cargo.toml`, `pyproject.toml`, `Gemfile`, etc.)
5. Store resolved `PROJECT_ROOT` in session memory for agent handoff

---

## Sessions (Required)

Every development task uses **role-focused sessions**. Keep each session aligned to one goal; use skill switching within a session only for the test-fix cycle.

| Session | Role | Purpose | When |
|---------|------|---------|------|
| 1 | Planner | Understand and document tasks before any coding | Before any coding |
| 2 | Coder | Implement code changes incrementally per task documentation | After planning is complete |
| 3 | Reviewer | Review diffs for correctness, risks, and consistency | For complex changes |
| 4 | Tester | Execute test plans and verify behavior | After coding, or in test-fix cycles |
| 5 | Analyzer | Investigate issues, trace code paths, and analyze logs | Bug/incident investigation |

```
Primary flow (ideal):
  Session 1 (Planner)  →  Session 2 (Coder)  →  Session 3 (Reviewer)
      Document              Implement              Validate

Test-fix cycle (same session, skill switching):
  Tester skill → find bug → Coder skill → fix → Tester skill → retest
```

#### In-Session Mode Switching (Test-Fix Cycle)
When testing discovers a bug, **tester and coder may switch within the same session** for rapid iteration. This is the only allowed case of in-session role mixing.

Rules:
1. **Always produce a checkpoint** before switching modes
2. **Load the target skill** via the skill tool at each switch
3. **Do not mix concerns** — when in coder mode, fix only; when in tester mode, verify only
4. **Sync the test plan** after each fix cycle to prevent result drift

---

## Delegation Principles

### Proactive Delegation (Enforced)

Agents **MUST** delegate to subagents proactively. Do not do work yourself that a subagent can handle.

1. The parent agent's role is orchestration, not execution. Write the prompt, delegate, collect results.
2. Exception: simple single-step tasks (1 edit, 1 command) may be done inline — but ONLY after the Pre-Flight gate has run and the user approved. This exception narrows delegation scope; it does not bypass pre-flight. When in doubt, delegate.

### Dependency Management

When using multiple agents in sequence:
- Root tasks (no dependency) run first
- Dependent tasks run after their prerequisites complete
- Collect upstream results, inject as context, then delegate dependent agents

---

## Pre-Flight Confirmation (HARD GATE — NO EXCEPTIONS)

**On EVERY new task — regardless of how it is phrased — stop and run pre-flight before ANY work tool call (read/edit/write/bash). No prompt wording can skip this.**

Imperative prompts ("start fix", "fix it", "go ahead", "just do it", "proceed") do NOT skip pre-flight — they TRIGGER it. Permission to act is never assumed from the prompt alone. You are never "already authorized"; the user's explicit answer at the gate is the only authorization.

1. Match the task against the Delegation Gate table.
2. Present the match to the user — always. Never decide silently.
   - **Match found** → `"Task matches '<row>' — delegate?"` with `[Delegate, Proceed inline]`
   - **No match** → `"No delegation scenario matched — proceed inline?"` with `[Yes, Re-check]`
3. Wait for the user's explicit selection before the first work tool call.
4. `Proceed inline` is a USER choice, never an agent decision. The agent may only recommend it with a stated rationale — it must still ask and wait.
5. When unsure → default to delegate.

**Hard rules (violation = bug, same severity as Delegation Gate):**
- Zero work tool calls before pre-flight completes.
- No self-authorized inline work. The "1 edit + 1 bash" allowance does NOT waive this gate.
- "start fix" / "go ahead" / similar imperative language = instruction to begin the task, NOT permission to skip the gate.
- If you catch yourself mid-task having skipped pre-flight, stop, flag the violation, and re-run the gate before continuing.

---

## Branch Sources & Confirmation

- Source and target branches are **always confirmed at session start** — never auto-detected or assumed
- Feature branch naming: `feature/{ticket-id}-{short-description}`
- Bugfix branch naming: `bugfix/{ticket-id}-{short-description}`

---

## File Naming
Task docs: `{YYYYMMDD}-{ticket-id}-{title}.md` **(ENFORCED — all task docs must follow this format; date, ticket, and title separated by hyphens)**

---

## Changelogs
Task documentation lives in the `changelog/` folder (singular) in each service repository. Do NOT use `changelogs/` (plural).

---

## Anti-Patterns (MUST AVOID)

- [ ] Jump into coding without full context
- [ ] Generate large, unreviewable code blocks
- [ ] Assume missing requirements
- [ ] Perform hidden refactors
- [ ] Mix planning and coding in one session
- [ ] No coding without task documentation
- [ ] No large code dumps (show diffs/snippets only)
- [ ] Modify test scripts to fix a validation bug — fix the source layer; test scripts are diagnostic tools, not the fix target
- [ ] Present neutral test results when expected behavior is violated — explicitly flag it as a bug with severity
- [ ] Do the work yourself when a subagent can handle it — proactive delegation is mandatory

---

## General Behavior

- Do not assume missing requirements
- Ask clarifying questions when requirements are unclear or incomplete
- Highlight assumptions before proceeding when context is uncertain
- Reconfirm scope if new information changes the task

---

## Safety Rules

- Do not modify unrelated code
- Do not refactor unless required by the task
- Do not remove functionality without confirmation
- Preserve backward compatibility unless explicitly approved otherwise
- Explicitly call out breaking changes / side effects

---

## Implementation Standards

- Follow existing project conventions and architecture
- Reuse existing utilities/patterns before introducing new ones
- Prefer minimal diffs over broad rewrites
- Keep changes scoped to the requested task only

---

## Workflow Discipline

- Work incrementally in logical steps
- Implement one logical change at a time unless instructed otherwise
- Keep output concise and focused on relevant diffs/snippets

---

## Testing

- Review existing tests before adding new ones
- Add/update tests when behavior changes require coverage
- Provide manual test scenarios when relevant

### Reviewer — Test Execution
- **Do NOT run tests locally if CI pipeline is green.** Trust CI, focus on static analysis.
- Only run tests locally when CI is unavailable or results are ambiguous.

---

## Branch Defaults

- Assume starting branch is the project's default branch unless specified otherwise
- Feature branch naming: `feature/{ticket-id}-{short-description}`
- Bugfix branch naming: `bugfix/{ticket-id}-{short-description}`

---

## Isolated Worktrees

Multi-agent workflows use isolated `git worktree` directories to keep each agent's workspace independent and prevent branch conflicts.

### Naming Convention

```
.worktrees/{ticket-id}-{short-description}/
```

Examples:
- `.worktrees/PROJ-12-bugfix/`
- `.worktrees/PROJ-34-auth-migration/`
- `.worktrees/BUG-56-null-pointer/`

### Path Resolution

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
TICKET_ID=<from confirmed context>
SHORT_DESC=<from branch name, e.g. "bugfix">
WORKTREE_PATH="$REPO_ROOT/.worktrees/$TICKET_ID-$SHORT_DESC"
```

### Creation

```bash
# From the main repo — create worktree tracking an existing branch
git worktree add "$WORKTREE_PATH" "$BRANCH"

# Or create with a new branch from a base
git worktree add -b "$BRANCH" "$WORKTREE_PATH" "$BASE_BRANCH"

# Add to .gitignore (first time in this repo)
echo ".worktrees/" >> "$REPO_ROOT/.gitignore"
```

### Confirmation Protocol

Every agent that needs a worktree **must confirm with the user** before proceeding.

- If `WORKTREE_PATH` is provided in shared context → confirm: "Work on `PROJ-12-bugfix` at `$WORKTREE_PATH`?"
- If not provided → ask: "Which ticket/branch should I work on?"

Agents never silently choose a worktree.

### Cleanup

After the MR is merged:

```bash
git worktree remove ".worktrees/$TICKET_ID-$SHORT_DESC"
git worktree prune   # clean up stale metadata
```

---

## Context Management

### Auto-Compact (Enforced)

Periodically compact context during long active sessions to optimize token usage. This is **mandatory** — not optional.

**When to trigger:**
- Every **5 significant turns** in the same session (a "turn" = user message + agent response)
- When conversation exceeds ~50K estimated input tokens
- Before delegating to a subagent (fresh subagent gets a clean context anyway, but the parent should compact first)
- When switching to a different task/scope within the same session

**How to compact:**
1. Provide a structured restart summary (see format below)
2. Recommend opening a **new session** with that summary — the summary becomes the first message
3. The current session can be closed

**Do NOT** try to manually prune/rewrite conversation history — that's lossy and error-prone. Always recommend a fresh session with a clean summary.

### Manual Cleanup

If conversation context becomes long, inconsistent, or noisy:
- Recommend starting a fresh session
- Provide restart summary including:
  - Ticket / Task
  - Confirmed Scope
  - Completed Work
  - Remaining Steps
  - Risks / Assumptions

---

## Commit & MR Rules

### Commit Format

```
{type}: {short description}

- Key change 1
- Key change 2
```

### MR Requirements

- Summary of changes
- Link to JIRA ticket
- Testing notes
- Risks / limitations

**MR Description Template:**

```
## Summary
<brief description of changes>

## JIRA
<JIRA ticket URL>

## Testing
<how to test, test results, manual scenarios>

## Risks / Limitations
<any risks, breaking changes, or known limitations>
```

---

### MCP Protocols

**All MCP servers now run through the `9router-gateway` MCP server.** All MCP tools are accessed through this gateway.
- **Endpoint:** `${ROUTER9_GATEWAY_URL}`
- **Auth:** Pass your Gateway Key as a Bearer token (`Authorization: Bearer ${ROUTER9_GATEWAY_KEY}`), a header (`x-api-key: <key>`), or a query parameter (`?key=<key>`).
- **Namespacing:** Tools are prefixed with their instance slug: `<slug>__<toolName>` (e.g., `firecrawl__scrape`, `context7__query-docs`).

To add the gateway to your MCP configuration (e.g., `~/.claude/mcp.json` or `~/.config/opencode/opencode.json`):

```json
"9router-gateway": {
  "type": "remote",
  "url": "${ROUTER9_GATEWAY_URL}",
  "headers": {
    "Authorization": "Bearer ${ROUTER9_GATEWAY_KEY}"
  }
}
```

Remove standalone MCP server entries once configured.

### Context7 — Library Documentation

Use `context7__resolve-library-id` and `context7__query-docs` (via the gateway) to fetch current documentation whenever the user asks about a library, framework, SDK, API, CLI tool, or cloud service — even well-known ones like React, Next.js, Prisma, Express, Tailwind, Django, or Spring Boot. This includes API syntax, configuration, version migration, library-specific debugging, setup instructions, and CLI tool usage. Use even when you think you know the answer — your training data may not reflect recent changes. Prefer this over web search for library docs.

**Do not use for:** refactoring, writing scripts from scratch, debugging business logic, code review, or general programming concepts.

### Steps

1. Call `context7__resolve-library-id` with `libraryName` and `query` — unless the user provides an exact library ID in `/org/project` format
2. Pick the best match (ID format: `/org/project`) by: exact name match, description relevance, code snippet count, source reputation (High/Medium preferred), and benchmark score (higher is better)
3. Call `context7__query-docs` with the selected library ID and the user's full question (not single words)
4. Answer using the fetched docs

---

### Firecrawl — Web Scraping & Research

Web scraping, search, and research — primary web tool via the gateway.

**Priority:** firecrawl (gateway) > Exa web search

**Search & discovery:**
- `firecrawl__firecrawl_search` — open-ended questions, multi-source research
- `firecrawl__firecrawl_developer_search` — developer/technical searches
- `firecrawl__firecrawl_map` — discover URLs on a site
- `firecrawl__firecrawl_feedback` / `firecrawl__firecrawl_search_feedback` — search feedback

**Extraction & scraping:**
- `firecrawl__firecrawl_scrape` — known URL, need page content (markdown or JSON)
- `firecrawl__firecrawl_extract` — structured data from specific pages
- `firecrawl__firecrawl_parse` — parse local files (PDF, DOCX, XLSX, etc.)
- `firecrawl__firecrawl_crawl` — bulk extraction across pages
- `firecrawl__firecrawl_check_crawl_status` — crawl progress

**Browsing & interaction:**
- `firecrawl__firecrawl_interact` — click, fill forms, navigate JS-rendered pages
- `firecrawl__firecrawl_interact_stop` — stop an active interaction session
- `firecrawl__firecrawl_agent` / `firecrawl__firecrawl_agent_status` — complex multi-step web research

**Monitoring:**
- `firecrawl__firecrawl_monitor_create` — track page changes over time
- `firecrawl__firecrawl_monitor_update` / `firecrawl__firecrawl_monitor_delete` / `firecrawl__firecrawl_monitor_get` / `firecrawl__firecrawl_monitor_list` — manage monitors
- `firecrawl__firecrawl_monitor_check` / `firecrawl__firecrawl_monitor_checks` / `firecrawl__firecrawl_monitor_run` — monitor runs & results

**Research (arXiv/GitHub):**
- `firecrawl__firecrawl_research_search_papers` — arXiv paper discovery
- `firecrawl__firecrawl_research_read_paper` / `firecrawl__firecrawl_research_inspect_paper` — read/inspect papers
- `firecrawl__firecrawl_research_related_papers` — related paper suggestions
- `firecrawl__firecrawl_research_search_github` — GitHub code/project search

**Format selection:** Use `json` + schema for specific data fields; use `markdown` for full page content.

---

### Metabase — Analytics Dashboards

Use `metabase-testing__*` tools via the gateway (registered instance slug: `metabase-testing`).

**Available environments:**
- Testing: `metabase-testing` — verification before production

**Workflow:**
1. `metabase-testing__list_databases` — find target DB
2. `metabase-testing__list_cards` / `metabase-testing__get_card` — inspect existing questions
3. `metabase-testing__execute_query` — ad-hoc SQL; `metabase-testing__create_card` — new saved questions
4. `metabase-testing__create_dashboard` / `metabase-testing__add_card_to_dashboard` — dashboard builds

**Permissions:** Use `metabase-testing__list_permission_groups` / `metabase-testing__get_collection_permissions` before modifying access.

---

### Jam — Bug Reports & Session Replays

Access Jam (jam.dev) bug reports and replays via the gateway (registered instance slug: `jam` — e.g., `jam__getDetails`, `jam__listJams`).

**Core flow (video/screenshot Jams):**
1. `jam__getDetails` — fetch Jam metadata (author, description, type, timestamps). Always call first to confirm type.
2. `jam__getVideoTranscript` / `jam__getVideoChapters` — speech transcript (WebVTT) and AI chapters for video Jams.
3. `jam__getConsoleLogs` / `jam__getNetworkRequests` / `jam__getUserEvents` — runtime errors, network activity, and interaction timeline.
4. `jam__getFrames` — extract visual still frames (overview grid, or `at`/window sampling) from video Jams.
5. `jam__getScreenshots` — image attachments from screenshot-type Jams only.
6. `jam__analyzeVideo` — extract user intents from a recording.
7. `jam__getMetadata` — custom metadata from the `jam.metadata()` SDK.

**Discovery & team:**
- `jam__search` — resolve a Jam from a UUID or jam.dev URL.
- `jam__listJams` / `jam__listMembers` / `jam__listFolders` — browse reports, find authors, organize.
- `jam__createFolder` / `jam__updateFolder` / `jam__deleteFolder` — manage folders (delete is destructive & irreversible; confirm first).

**Comments & reactions:**
- `jam__createComment` / `jam__editComment` / `jam__deleteComment` — notes on a Jam (Markdown; delete is destructive).
- `jam__addReaction` / `jam__removeReaction` — emoji reactions (🐛 💜 ✅ 👀 ❓ 👏 🔥 👍).

**Recording links:**
- `jam__listRecordingUrls` — connected domains (needed for logs).
- `jam__createRecordingLink` / `jam__updateRecordingLink` / `jam__getRecordingLink` / `jam__listRecordingLinks` / `jam__listRecordingLinkJams` / `jam__deleteRecordingLink` — manage reusable recording links.
- `jam__getRecordingUrlVerifyLink` — returns a verify URL a human must open to verify a connected domain.

**Updates & deletion:**
- `jam__updateJam` — rename, rewrite description, or move between folders.
- `jam__deleteJam` — destructive & not recoverable; confirm with the user first.

---

### Sequential Thinking — Structured Reasoning

Use `sequential-thinking__sequentialthinking` via the gateway for high-ambiguity tasks.

This tool is **NOT** for default reasoning. Modern models already reason internally.

**When to use (conditional — only for high-ambiguity tasks):**
- **Planner**: Large refactors, migrations, architectural changes
- **Reviewer**: Complex diff analysis with cross-cutting concerns
- **Analyzer**: Root cause investigation with branching hypotheses

**When NOT to use:**
- **Coder**: Never during implementation — execute, don't philosophize
- **Tester**: Never during normal test execution
- Any execution-heavy task (shell, filesystem, edit loops)

**Rules:**
- Max **5 thoughts** per invocation — no infinite chains
- **No revisions** — commit and move forward
- **No branching** — linear chain only
- If unsure after 5 thoughts, ask the user clarifying questions to proceed
- Prefer fast execution over thorough decomposition for simple tasks

---

### Lean-ctx — Code Intelligence

Provides fast, context-aware code exploration and understanding. Available as a bundled Warp skill (`lean-ctx`).

**MANDATORY TOOL SELECTION:**
- Understand code / find answers / before editing → `ctx_compose` (call FIRST)
- Read a file → `ctx_read` (use mode=signatures for overview, mode=full for details)
- Find a symbol by name (exact) → `ctx_symbol`
- Search code by pattern (fuzzy) → `ctx_search`
- Search by meaning (concepts) → `ctx_semantic_search`
- Find files by pattern (glob) → `ctx_glob`
- Project structure → `ctx_tree`
- Who calls this / call graph → `ctx_callgraph`
- Session state / memory → `ctx_session` / `ctx_knowledge`

**Anti-patterns — do NOT:**
- Chain ctx_search → ctx_read → ctx_symbol — one ctx_compose replaces all three
- Use ctx_read(mode=full) for orientation — use mode=signatures
- Use ctx_callgraph for const/static/variable references — use grep or ctx_compose instead

**PARALLEL tool calls:** fire independent calls in the SAME turn — don't sequence them.
ctx_compose bundles multiple lookups into one call; for anything it doesn't cover, batch independent reads/searches together.

**Output style:** concise — bullet points over paragraphs, skip filler words and hedging, 1-sentence explanations max, then code/action.

---

### Serena — LSP Code Intelligence

Provides LSP-level code analysis alongside lean-ctx.

| Scenario | Tool |
|----------|------|
| Understand code structure | lean-ctx ctx_compose FIRST |
| Find symbol declaration | serena find_declaration |
| Find symbol references | serena find_referencing_symbols |
| Find implementations | serena find_implementations |
| Rename symbol across files | serena rename_symbol |
| Insert/replace/delete code | serena insert_after_symbol / replace_content / safe_delete_symbol |
| Get file diagnostics | serena get_diagnostics_for_file |

**Precedence:** lean-ctx for understanding/discovery, serena for precise LSP operations.
Prefer serena for rename/refactor that needs cross-file correctness.

---

### MCP Tool Coordination

When multiple MCPs overlap capabilities:
- **Code understanding** → lean-ctx ctx_compose first
- **Code editing** → serena symbol operations
- **Web research** → firecrawl__* via the gateway
- **Library docs** → context7__* via the gateway
- **Bug reports / session replays** → jam__* via the gateway
- **Analytics/SQL** → metabase-testing__* via the gateway
- **Structured reasoning (high-ambiguity only)** → sequential-thinking__sequentialthinking via the gateway

---

## Skill Files

Skill files for role-specific guidance are in: `~/.agents/skills/{name}/SKILL.md`

Available role skills:
- `planner` — Load for planning sessions
- `coder` — Load for coding sessions
- `review` — Load for review sessions
- `tester` — Load for testing guidance
- `analyzer` — Load for production issue investigation and root cause analysis

Utility skills:
- `system-wiper` — macOS/Homebrew cleanup and maintenance: outdated check → safety evaluation → upgrade/removal → dependency fix → cache cleanup → trash empty

---

## Local Tools

The following tools are available for development workflows:

### glab — GitLab CLI
Primary interface for GitLab merge requests and project management.

```bash
glab mr view <id>              # View MR details
glab mr diff <id>              # View MR diff
glab mr note <id> -m "review"  # Post a comment on MR
glab api <endpoint>            # Direct API access
```

### git-review-cli — MR Review Tool
Automates MR diff fetching, local checkout, and review posting.

```bash
git-review-cli https://gitlab.com/org/project/-/merge_requests/123
git-review-cli https://gitlab.com/org/project/-/merge_requests/123 --caveman   # Quick review
git-review-cli https://gitlab.com/org/project/-/merge_requests/123 --deep      # Deep review
git-review-cli <MR_ID>                    # Shorthand (current repo)
git-review-cli <ID> --post /tmp/review.md # Post a review file
```

**Prerequisite:** Authenticate glab first (`glab auth login` or set `GITLAB_TOKEN`).

### multilogs — Kubernetes Log Aggregation
Aggregate logs from multiple Kubernetes pods across services.

```bash
multilogs -s 10m -o <app1> <app2>     # Fetch last 10 min to file
multilogs <app-name>                   # Stream logs from all pods
multilogs -h                          # Show help
```

**Gotcha:** When called from a non-interactive shell (e.g., via bash tool), prepend `source ~/.zshrc`:
```bash
source ~/.zshrc && multilogs -s 10m -o core-api core-worker
```

### pod-app-list — List Kubernetes Apps
Lists all unique `app` labels from running pods.

```bash
pod-app-list   # Returns sorted, deduplicated app names
```

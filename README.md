# agents

Tool-agnostic AI-engineering workflow: role-based sessions, delegation gate, session chain, MCP wiring.

Drop-in `~/.agents/` for any agent harness (Warp, Claude Code, OpenCode, Hermes, etc.).

## What's inside

- `AGENTS.md` — the workflow spec: delegation gate, session chain, safety rules, MCP protocols.
- `skills/` — role skills (`planner`, `coder`, `review`, `tester`, `analyzer`), orchestrators (`sprint-bug-orchestrator`, `jira-sprint-orchestrator`, `sprint-review-orchestrator`), and utility skills (`firecrawl-*`, `context7-mcp`, `writer`, `system-wiper`, etc.).
- `mcp.json` — MCP client config pointing at the 9router-gateway with env-var placeholders.
- `env.template` — dummy credentials to copy into `.env`.
- `install.sh` — symlinks the repo into `~/.agents`.

## Install

```bash
git clone https://github.com/<you>/agents.git ~/agents
cd ~/agents
./install.sh
```

`install.sh` does three things:
1. Backs up any existing `~/.agents` (if it's a real directory, not a symlink).
2. Symlinks the repo into `~/.agents`.
3. Copies `env.template` to `.env` if missing.

After install, edit `.env` and fill in real values for:
- `ROUTER9_GATEWAY_URL` / `ROUTER9_GATEWAY_KEY` — MCP gateway
- `JIRA_URL` — your Jira base URL
- `TESTING_ENV_NAME` / `TESTING_ENV_URL` — testing environment identifiers

`.env` is gitignored. Never commit real secrets.

## Update

```bash
cd ~/agents
git pull
```

Changes appear in `~/.agents` immediately via the symlink.

## Uninstall

```bash
rm ~/.agents          # removes the symlink only
# your ~/.agents.bak.<timestamp> (if any) is untouched
```

## Design principles

- **Delegation gate.** Before any work tool call, the agent matches the task against a table of mandatory delegation scenarios. Match = delegate. No match = ask before proceeding inline.
- **Role-focused sessions.** One goal per session: Planner → Coder → Reviewer → Tester → Analyzer. The only allowed in-session mixing is the test-fix cycle (Tester ↔ Coder).
- **Pre-flight confirmation.** Before any work tool call on a new task, the agent stops and confirms delegation intent with the user. Imperative wording ("start fix", "go ahead") triggers pre-flight, it doesn't skip it.
- **Isolated worktrees.** Multi-agent workflows use `.worktrees/{ticket-id}-{short-description}/` to keep each agent's workspace independent.

See `AGENTS.md` for the full spec.

## License

MIT.

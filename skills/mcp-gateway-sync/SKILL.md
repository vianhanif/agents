---
name: mcp-gateway-sync
description: >
  Audit and synchronize the MCP integration guide across AGENTS.md, skill files,
  and the Claude MCP client config so everything matches the live 9router-gateway
  state. Use this skill whenever the user mentions MCP integration docs, wants to
  check that AGENTS.md or skills match the gateway, registers or removes an MCP
  instance on the gateway, rotates a gateway key, or says "sync MCP", "check MCP
  docs", "update the MCP guide", "MCP integration is out of date", or asks why a
  gateway tool is missing from the docs. Make sure to use this skill even if the
  user only mentions a single MCP tool or server — drift in one prefix usually
  means drift in the whole section. Do NOT trigger for generic MCP usage
  questions or for non-MCP documentation edits.
---

# MCP Gateway Sync

Keep the MCP integration documentation in sync with the real 9router-gateway.
The gateway is the single source of truth: registered instance slugs, tool
namespaces, and key state. Docs (AGENTS.md, skill files) and the Claude client
config (`~/.claude/mcp.json`) must reflect that state, or agents will look for
standalone MCP servers that no longer exist and waste time.

## Source of truth

- Gateway endpoint: `${ROUTER9_GATEWAY_URL}`
- Auth for JSON-RPC: `Authorization: Bearer ${ROUTER9_GATEWAY_KEY}`, `x-api-key: <key>`, or `?key=<key>`
- Instance listing: `GET /api/mcp-gateway/instances` → `{ instances: [{ slug, title, transport, enabled, ... }] }`
- Key listing: `GET /api/mcp-gateway/keys` → list of key metadata (raw key values are NOT returned — they are revealed once at creation)

## Trigger conditions

Run the full sync when:
- The user asks to check/update MCP integration docs
- A gateway instance was added, removed, renamed, or toggled
- A gateway key was created or revoked
- You suspect the docs reference a slug that does not exist

## Workflow

### 1. Probe the gateway

Verify the gateway is live, then collect ground truth.

```bash
curl -s -m 5 "${ROUTER9_GATEWAY_URL}/health"
curl -s -m 5 "${ROUTER9_GATEWAY_URL}/instances"
curl -s -m 5 "${ROUTER9_GATEWAY_URL}/keys"
```

Extract from instances: slug, title, transport, enabled. Build the expected
namespace list: `<slug>__*` for each enabled instance.

If the gateway is down (`/api/health` not OK), do NOT patch anything — report
"gateway unreachable" and stop. Docs cannot be synced against a dead source of
truth.

### 2. Audit the docs

Read the files that carry MCP integration guidance:

- `~/.agents/AGENTS.md` — the `## MCP Protocols` section and the `### MCP Tool Coordination` block
- `~/.agents/skills/*/SKILL.md` — any skill that mentions MCP tools, gateway, or tool prefixes (e.g. `firecrawl*`, `context7-mcp`, and any future MCP-backed skills)

For each file, check:
- **Slugs**: every documented `<slug>__` prefix matches a registered enabled instance slug
- **Endpoint**: any documented URL matches `${ROUTER9_GATEWAY_URL}`
- **Auth**: auth mechanism matches the gateway (Bearer / x-api-key / `?key=`)
- **Standalone references**: any mention of a standalone MCP server that is now registered on the gateway should point at the gateway instead
- **Missing entries**: an enabled instance with no docs coverage should be added

Use grep to find MCP references efficiently:

```bash
grep -rn "9router-gateway\|mcp-gateway\|__firecrawl\|__context7\|__jira\|__kubectl\|__metabase\|__sequential-thinking" ~/.agents/AGENTS.md ~/.agents/skills/
```

### 3. Report drift

Present the diff between ground truth and docs before writing anything. Format:

```
Gateway instances: firecrawl, sequential-thinking, jira, kubectl-mcp, context7, metabase-testing
Docs drift:
- AGENTS.md: prefix `jira__jira_get_issue` references nonexistent slug `jira-jira` — expected `jira__get_issue`
- skills/firecrawl/SKILL.md: OK
- skills/context7-mcp/SKILL.md: OK
```

Confirm the patch list with the user, then apply. Do not silently rewrite docs.

### 4. Patch the docs

Fix only the drift you found. Follow these conventions:

- Use the exact registered slug: `<slug>__<toolName>`
- For sections listing many tools of one instance (e.g. Firecrawl), keep the list but fix prefixes
- For instances whose exact tool names you cannot verify, write `<slug>__*` and note "check the gateway's tools/list for exact tool names" — never invent tool names
- Prefer "via the gateway" over repeating endpoint details in every section; the endpoint lives in the MCP Protocols header

### 5. Sync the client config

Ensure `~/.claude/mcp.json` contains the `9router-gateway` entry and that
standalone servers registered on the gateway are removed (or disabled) so agents
do not connect to them directly.

Required entry shape:

```json
"9router-gateway": {
  "type": "remote",
  "url": "${ROUTER9_GATEWAY_URL}",
  "headers": {
    "Authorization": "Bearer ${ROUTER9_GATEWAY_KEY}"
  }
}
```

Key handling rules:
- If a gateway key is already present in the config, leave it untouched
- If no key is present, ask the user for it (raw keys are revealed once at creation in the 9router dashboard). Do NOT scrape the gateway DB or log files for key material
- Never print, echo, or store the key in commit-able files or chat where avoidable
- Keep other non-gateway MCP servers (e.g. duckdb, mcp-mermaid) as-is unless the user asks to migrate them

### 6. Verify

Re-run the audit grep and confirm zero drift remains. Report the final state.

## Guardrails

- Never guess a slug. If it is not in `/api/mcp-gateway/instances`, do not document it
- Never invent tool names. `<slug>__*` + pointer to `tools/list` is correct when unsure
- Never write config when the gateway is unreachable
- Never modify `~/.config/opencode/opencode.json`
- Never print or persist raw gateway keys
- Docs-only change (no key, no config write) still requires the drift report before editing

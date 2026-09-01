---
name: writer
description: Structured drafting and reviewing pipeline using child agents. Orchestrates writing, cold-read review, and iterative revision until readiness threshold is met.
---

# Writer Skill

## Workflow

### Phase 1: Research & Context
- If user provides an existing draft or says "review this," skip Phase 1-2 and proceed directly to Phase 3. No context-gathering needed.
- Collect topic, target audience, key points, and existing source material
- Identify structural problems upfront (too dense, missing stakes, flat narrative)
- Define target length and tone

### Phase 2: Draft
- Write first draft with clear hook, stakes, and narrative arc
- Emphasize: AI is editorial assistant, not ghostwriter — human drives all decisions
- End with open questions for review

### Phase 3: Spawn Cold-Read Agents (MANDATORY)
Launch 2+ child agents to review the draft independently.

**Naming convention:** Use unique, session-isolated names to avoid collision across sessions and allow multiple review rounds. Format: `{role}-{short-slug}-{round}`. Examples: `cold-reader-kubelogs-v1`, `human-reader-kubelogs-v1`, `cold-reader-pidfile-v2`. Do NOT reuse bare role names (`agent-cold-reader`, `agent-human-reader`) — those persist across sessions and cause launch rejection.

**agent-cold-reader** — technical review
- Line-level critique: structure, tone, clarity, thesis
- Flag missing steps, unexplained terms, logical gaps
- Score 0-100% on readiness

**agent-human-reader** — authenticity review
- Read as skeptical tech reader who found this on a blog
- Evaluate: hook, authenticity, value, forced or natural tone
- Score 0-100% on readiness

### Phase 4: Iterative Revision
- Examine score gap between reviewers — divergence signals missing texture.
  - Human-reader score <75% = narrative problem (hook, stakes, authenticity). Prioritize story rewrite over line edits.
  - Cold-reader score <75% = technical problem (gaps, accuracy, structure). Prioritize logical completeness over phrasing.
- **Verify before acting:** Orchestrator must verify reviewer-flagged technical issues (frontmatter, code errors) against the actual file before applying fixes. Reviewers may hallucinate false positives.
- Apply fixes: before/after evidence, failure anecdotes, concrete numbers
- Do NOT let agents write fixes — human fills gaps based on flagged issues
- **Round versioning:** After each revision round, increment the round number in agent names (e.g. `-v1` → `-v2`) when re-launching cold-read agents. Keeps parallel review rounds distinct and traceable.
- Re-launch cold-read agents after revision

### Phase 5: Sign-off
- Target: both reviewers score 90%+
- Remove duplicate content, fix Sources, ensure cross-links
- Final read-through before publish

### Phase 6: Cross-File Sync (MANDATORY)
Sync title, frontmatter, and metadata across all associated files:
- `_posts/` — canonical source of truth for title, date, tags, layout
- `_medium/` — must match post title and linked_posts path
- `_linkedin/` — must match post title and linked_posts path

**Workflow:**
- If title changes (user request or iteration), update ALL three files atomically
- Verify linked_posts paths match the actual post permalink
- Do NOT change body content in _medium/ or _linkedin/ unless the user approves
- Commit across all changed files in a single commit (or logical sequence)

**Title suggestion sub-pattern:**
When user asks for title alternatives, follow iterative loop:
1. Read post content to understand core narrative and two-layer structure
2. Suggest 4-5 titles. Each must pass a fitness rubric:
   - **Clarity:** does it describe what happened, or is it cryptic?
   - **Accuracy:** does the title match the story's actual structure and root causes?
   - **Ambiguity check:** would a reader immediately know the scope (systems involved, failure type)?
   - **Key systems:** mention or imply the primary systems (Warp/Warp agent, 9router, Cloudflare)
   - **Hook:** scannable and interesting to the target audience
3. When user gives new criteria or constraint, re-suggest with that constraint applied
4. When user asks to evaluate a specific title, assess each rubric dimension explicitly

**Anti-pattern:** Suggesting titles without reading the post first. Cryptic/ambiguous titles that don't name the systems involved.

### Phase 7: Publishing Staging (MANDATORY for publish-ready posts)

Execute the publishing orchestration rules defined in the writings AGENTS.md (`~/Documents/work/.ai/writings/AGENTS.md`). Summary:

**Pre-publish checks:**
- Confirm post date frontmatter reflects the actual publish date (update from future date to current)
- `_linkedin/` teaser generated from post content (3 items per topic group)
- `_medium/` prep generated as expanded story with inline links back to blog, it should be has more content than linkedin, but remain brief so reader get curious enough to read the full post
- Both files use their respective templates (frontmatter structure, sections, notes checklist)
- Sources section present in blog post with HTTPS URLs

**Publishing sequence:**
1. Blog post goes live (GitHub Pages deploy on push to main/master)
2. Medium published same day (via https://medium.com/p/import, paste content, set canonical URL)
3. LinkedIn scheduled via Fedica for next day (D+1) — text-only teaser + first-comment with Medium link

**Key constraints:**
- Medium content is original, not cross-post — no canonical URL
- LinkedIn scheduled, not posted immediately (Fedica)
- Wait 2-4 weeks between blog publish and Medium publish (SEO spacing) — unless user says otherwise

**Anti-pattern:** Publishing blog post without generating/updating linkedin and medium prep files.

## Rules

- **Human drives.** Agents critique and suggest. Human writes final content.
- **Two reviewers minimum.** One technical cold-read, one human-perspective reader.
- **No ghostwriting claims.** Post must not claim AI wrote it — claim AI helped edit.
- **Iterate to 90%.** Don't publish until both reviewers score 90%+.
- **Self-awareness.** If the post is about the pipeline itself, include a "Pipeline Eats Its Own Tail" section acknowledging the review gap.

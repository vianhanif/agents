---
name: system-wiper
description: |
  Perform comprehensive system cleanup and maintenance. Triggers whenever the user mentions cleanup, system health, brew maintenance, cache clearing, disk space, system maintenance, upgrade check, or wants to tidy up their macOS/Homebrew environment. Use this skill proactively when the user asks about system status or package management. This skill handles the full lifecycle: outdated check → safety evaluation → upgrade/removal → dependency fix → cache cleanup → trash empty.
---

# System Wiper

Handles macOS system cleanup, Homebrew maintenance, cache purging, and disk space management.

## How to Use

Invoke with `/system-wiper` or natural language like:
- "check brew status"
- "cleanup my system"
- "free up disk space"
- "run brew maintenance"
- "what can I clean up"
- "system health check"

---

## Workflow

Run checks in this order — each step informs the next:

1. **Check outdated**: `brew outdated`
2. **Check health**: `brew doctor`
3. **Check missing deps**: `brew missing`
4. **Evaluate and act**: Based on findings, propose upgrade/removal/trust/untap
5. **Cleanup**: `brew cleanup --prune=all`
6. **System-wide cache scan**: Check and report on major cache directories
7. **Final health check**: `brew doctor` + `brew missing` to confirm clean state

---

## Safety Guidelines

### Always Confirm Before These Actions

These require explicit user confirmation before executing:

| Action | Reason |
|---|---|
| Tap trust (`brew trust`) | Grants full trust to all formulae in the tap |
| Tap untap (`brew untap`) | Irreversible, fails if formulae are installed |
| Formula uninstall | Can break dependent packages |
| Docker prune (`docker system prune -a`) | Removes all unused images/containers/volumes |
| Trash empty | Files are permanently deleted |

### Auto-Proceed (No Confirmation Needed)

Safe operations that can proceed without asking:

| Action | Why Safe |
|---|---|
| `brew outdated` (read-only) | No changes made |
| `brew doctor` (read-only) | Diagnostic only |
| `brew missing` (read-only) | Diagnostic only |
| `brew cleanup --prune=all` | Removes only outdated bottles from cache |
| Cache directory deletion for known caches (npm, playwright, opencode, mole) | Regenerated on next use |
| `brew install` for missing dependencies | Fixes broken state |

### Never Do These

| Prohibition | Reason |
|---|---|
| Do NOT run `docker system prune -a` without checking if Docker is running | Wastes time, may error, does nothing useful |
| Do NOT remove `icu4c@77` without checking `brew uses --installed` | Breaks dependent formulae (e.g. jmeter) |
| Do NOT use Finder applescript for Trash if Finder not running | Fails silently; use `rm -rf ~/.Trash/*` instead |
| Do NOT assume a deprecated formula is unused | Check `brew uses --installed` first |
| Do NOT clear caches mid-session for actively-used tools | Can interrupt running workflows |
| Do NOT auto-trust taps | Tap trust is broad; user must consent |

---

## Homebrew Safety Evaluation

When evaluating upgrade candidates, use this framework:

### Safe — Auto-Proceed (Patch/Minor Bumps)

Any version bump within the same major.minor.patch scheme, or ca-certificates date bumps.

Examples: `1.2.3 → 1.2.4`, `1.2.3 → 1.3.0` (if changelog shows no breaking changes), `git 2.54.0 → 2.55.0`

### Review First — Ask User (Major Bumps or Risky)

- Major version jumps (e.g. `1.x → 2.x`)
- Packages with known breaking changes in release notes
- Runtime library formulae that other packages depend on (e.g. `libffi`, `openssl@3`, `icu4c`)

Present evaluation table with current → new version, then wait for user confirmation.

### Uninstall Candidates

- Deprecated formulae (flagged by `brew doctor`)
- Packages the user explicitly requests removal of
- Orphaned taps with no installed formulae (after user confirms)

### Tap Trust Issues

1. If `brew doctor` reports untrusted taps, present options to user
2. **Trust the tap**: `brew trust <tap>` (after user confirms)
3. **Untap**: `brew untap <tap>` (fails if installed formulae exist — uninstall them first)

---

## System-Wide Cache Scan

After Homebrew cleanup, scan these areas and report sizes. Propose cleanup for anything over ~50MB.

```bash
# Homebrew cache
du -sh ~/Library/Caches/Homebrew

# Node/npm
du -sh ~/.npm

# Python package managers
uv cache dir && du -sh ~/.cache/uv
du -sh ~/Library/Caches/pip
du -sh ~/.cache/pip

# Development tool caches
du -sh ~/Library/Caches/ms-playwright
du -sh ~/.cache/opencode
du -sh ~/.cache/mole

# Docker
docker system df 2>/dev/null || echo "Docker not running"
du -sh ~/.docker/

# Rust/Cargo
du -sh ~/.cargo/registry ~/.cargo/git

# Xcode/Developer
du -sh ~/Library/Developer/Xcode/DerivedData
du -sh ~/Library/Developer/CoreSimulator/Caches

# Logs
du -sh ~/Library/Logs
du -sh /var/log

# iOS backups
du -sh ~/Library/Application\ Support/MobileSync/Backup/
```

Report sizes sorted by size (largest first).

### Cleanup Commands by Cache Type

| Cache | Clean Command | Confirm Needed? |
|---|---|---|
| npm | `npm cache clean --force` | No |
| Homebrew bottles | `brew cleanup --prune=all` | No |
| Playwright browsers | `rm -rf ~/Library/Caches/ms-playwright` | No |
| OpenCode | `rm -rf ~/.cache/opencode` | No |
| mole | `rm -rf ~/.cache/mole` | No |
| uv | `uv cache clean` | No |
| pip | `pip cache purge` | No |
| Docker images/containers | `docker system prune -a` | **Yes — Docker must be running** |
| Trash | `rm -rf ~/.Trash/*` | No |
| Colima/Lima stale VM | `rm -rf ~/.colima ~/.lima` | **Yes — check colima status first** |

---

## Colima / Lima VM Check

If Docker commands fail (socket not found):

1. Run `colima status`
2. If not running: check `du -sh ~/.colima/`
3. If directory is empty or small: flag for potential removal
4. Only remove if user confirms

---

## Dependency Repair

### Missing Dependencies

1. `brew missing` identifies which formula needs them and what's missing
2. Run `brew install <missing-dep>`
3. Re-run `brew doctor` to confirm resolved

### Deprecated Formulae

1. Check `brew uses --installed <formula>` to find dependents
2. If dependents exist and are important: leave the deprecated formula, note it in report
3. If no dependents: safe to remove after user confirms
4. If dependents exist but user wants to remove anyway: uninstall dependents first

---

## Final Report

After all cleanup, always produce a summary:

```
## Cleanup Summary

| Category | Action | Result |
|---|---|---|
| Packages upgraded | git, rust, node, ... | X packages updated |
| Packages removed | asciinema, gitlab-runner | X packages uninstalled |
| Caches cleared | playwright, npm, opencode, mole | ~X GB freed |
| Brew cleanup | bottles + manifests | ~X MB freed |
| Trash | emptied | X files removed |

**Total disk space reclaimed**: ~X.X GB

**Remaining warnings**:
- `icu4c@77` deprecated (pinned by jmeter — harmless until jmeter updates)
- X other items (explain each)

**System status**: ✅ Ready
```

---

## Anti-Patterns

1. Do NOT run `docker system prune -a` without first checking if Docker is running (`docker info`)
2. Do NOT remove `icu4c@77` without checking dependents via `brew uses --installed icu4c@77`
3. Do NOT use `osascript` Finder Trash empty — use `rm -rf ~/.Trash/*` instead (Finder may not be running)
4. Do NOT assume deprecated = unused — always check dependents first
5. Do NOT clear caches mid-session for tools the user may be actively using
6. Do NOT present a wall of commands without explaining what each does
7. Do NOT proceed with upgrades without first checking `brew doctor` and `brew missing`

---

## Example Session Flow

```
brew outdated
  → reports: git 2.54.0 < 2.55.0, rust 1.96.0 < 1.97.0

brew doctor
  → reports: untrusted tap steipete/tap, icu4c@77 deprecated

brew missing
  → reports: python@3.12 missing for gcloud-cli

brew install python@3.12
  → fixes missing dep

brew upgrade git rust
  → upgrades safe packages

brew trust steipete/tap
  → resolves tap warning

brew cleanup --prune=all
  → removes stale bottles

Cache scan:
  → ms-playwright 556MB, npm 199MB, opencode 123MB, mole 78MB

npm cache clean --force
rm -rf ~/Library/Caches/ms-playwright ~/.cache/opencode ~/.cache/mole
rm -rf ~/.Trash/*

brew doctor → "Your system is ready to brew"
brew missing → clean

Report:
  → 35 packages upgraded, ~1.7GB freed, system clean
```

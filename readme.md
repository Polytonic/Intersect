# Intersect

Single source of truth for AI-tool preferences shared across Claude Code, Codex CLI, and Gemini CLI. Named after [The Intersect](https://chuck.fandom.com/wiki/The_Intersect) from *Chuck*: one flash, instant download of every preference into the right place on every machine.

## Quickstart

```sh
# Installation
git clone https://github.com/Polytonic/Intersect.git
cd Intersect && ./bin/intersect install
intersect link
```

## Usage
```sh
intersect <command>
    doctor                diagnose CLI install, link symlinks, tool availability
    update                git pull --ff-only the repo (no need to cd)
    link [TOOL...]        symlink config files into ~/.<tool>/
    unlink [TOOL...]      remove config symlinks pointing into this repo
    install [DIR]         symlink intersect onto PATH (default: /usr/local/bin)
    uninstall [DIR]       remove the PATH symlink
```

`TOOL` is one or more of `all`, `claude`, `codex`, `gemini`. Both `install` and `link` are idempotent. Both `uninstall` and `unlink` only touch symlinks they own; real files are left alone.

## Layout

```
core/                                # universal markdown content
├── agents.md                        # coordinator profile entrypoint
├── claude.md                        # Claude wrapper (@-imports core/agents.md only)
├── styles/
│   ├── implementation.md            # coding, testing, debugging, formatting
│   └── prose.md                     # copy, writing, documentation style
├── primitives/
│   ├── personas.md                  # reviewer/expert roster
│   ├── tools.md                     # claude/codex/gemini affordances
│   ├── coordination.md              # multi-agent team patterns
│   └── interaction-design.md        # UI behavior, accessibility
└── pipelines/
    ├── code-review.md               # multi-phase persona review
    ├── expert-consultation.md       # single specialist dispatch
    ├── competitive-implementation.md  # divergent then converge ("red/blue")
    ├── cross-model-consultation.md  # Codex/Gemini second opinion
    ├── regression-test.md           # automated checks after code-modifying changes
    └── maintenance.md               # session-end capture and handoff

tools/                               # per-CLI machine config
├── claude/
│   ├── settings.json
│   └── statusline.sh
├── codex/config.toml
└── gemini/settings.json

bin/
├── intersect                        # CLI
└── verify-ai.sh                     # live, opt-in AI config verification
```

## Symlink map

| Symlink | → Repo file |
|---|---|
| `~/.claude/CLAUDE.md` | `core/claude.md` |
| `~/.claude/settings.json` | `tools/claude/settings.json` |
| `~/.codex/AGENTS.md` | `core/agents.md` |
| `~/.codex/config.toml` | `tools/codex/config.toml` |
| `~/.gemini/GEMINI.md` | `core/agents.md` |
| `~/.gemini/settings.json` | `tools/gemini/settings.json` |

`settings.local.json` is intentionally not symlinked. Per Anthropic's documented intent, `.local.json` is for machine-specific overrides that stay outside version control.

All runtime state (sessions, history, sqlite, caches, auth tokens) stays put in each tool's config directory. Nothing here touches it.

## Claude statusline

`tools/claude/statusline.sh` renders compact usage bars:

```text
Claude 5h [###-----] 39% 7d [#-------] 15% | Codex D [##------] 25% W [##------] 20%
```

Claude percentages come from Claude Code's statusline payload when rate-limit data is present. Codex percentages use `@ccusage/codex` cost data against explicit budgets: set `CODEX_DAILY_BUDGET_USD` and `CODEX_WEEKLY_BUDGET_USD` in the Claude environment. The weekly Codex bar is trailing seven calendar days. Without those budgets, Codex prints `--%` instead of inventing a denominator. The Codex report is cached for 300 seconds by default.

<details>
<summary><strong>Why lowercase repo files?</strong></summary>

Two reasons, one aesthetic and one technical:

1. The lowercase convention reads less like shouting.
2. Codex CLI auto-discovers project-level `AGENTS.md` files. If `Intersect/AGENTS.md` were uppercase, running Codex inside this repo would double-load it (project AGENTS.md plus the symlinked global one). Lowercase prevents the collision while the destination symlink (`~/.codex/AGENTS.md`) keeps the case Codex expects. macOS APFS is case-insensitive by default, so the collision risk exists only on case-sensitive volumes (or other OSes), but the lowercase convention costs nothing and removes the risk wherever it exists.

</details>

## Styles, primitives, and pipelines

The repo has three referenced layers below `agents.md`:

- **Styles** (`core/styles/`): implementation and prose rules loaded by the agent when a task calls for them.
- **Primitives** (`core/primitives/`): reusable building blocks (personas, tools, coordination patterns) loaded when the File Map or a brief names them.
- **Pipelines** (`core/pipelines/`): composed workflows loaded when the File Map or the task trigger points to them.

`core/agents.md` is the shared entry point. Its File Map indexes all three directories. Paths in briefs and docs should be repo-root relative, unless a quoted source says otherwise.

Adding a new pipeline: create `core/pipelines/<name>.md` describing trigger, steps, and synthesis. Reference any primitives it uses by path. Update the File Map in `core/agents.md` to list it.

Adding a new primitive: create `core/primitives/<name>.md`. Update the File Map in `core/agents.md`. Pipelines reference primitives by path.

## Tool compatibility notes

- **Claude Code** reads `~/.claude/CLAUDE.md` and resolves `@import` paths relative to the importing file. `core/claude.md` imports only `@./agents.md` at startup. Styles, primitives, and pipelines are referenced by the File Map and loaded by the agent when needed.
- **Codex CLI** reads `~/.codex/AGENTS.md`. No `@import` syntax. Styles, primitives, and pipelines are referenced by the File Map and loaded by the agent when needed.
- **Gemini CLI** reads `~/.gemini/GEMINI.md` by default. Supports `@file.md` imports (relative or absolute). This repo links Gemini to `core/agents.md`; styles, primitives, and pipelines are referenced by the File Map and loaded by the agent when needed.

## Verifying the setup

Three layers of verification, each catching a different kind of failure:

### 1. State (`intersect doctor`)

```sh
intersect doctor
```

Read-only inspection of current state: repo file presence, CLI install on PATH, every expected link symlink, tool availability with versions. Exits 0 when all is well, 1 when issues are found.

### 2. Logic (`bin/test.sh`)

```sh
bash bin/test.sh
```

Sandboxed in a temp `HOME` so it never touches your real `~/.claude` etc. Exercises the install/uninstall/link/unlink/doctor logic deterministically. Run after any change to `bin/intersect`. Exits non-zero on failure.

### 3. Live AI config pickup (`bin/verify-ai.sh`)

```sh
bin/verify-ai.sh
bin/verify-ai.sh codex
```

Opt-in provider-backed smoke checks for Claude, Codex, and Gemini. The script runs from a temp directory outside this repo and checks that each selected CLI can see the linked global config in another project context. It skips tools that are not installed. Do not run this in CI or pre-commit.

See [`test.md`](test.md) for the executable check and manual command table.

## For AI agents working in this repo

Source of truth for AI-tool preferences. After any change:

- Edits to `core/`: run the matching AI verification command from [`test.md`](test.md) for the affected tool.
- Edits to `bin/intersect`: run `bash bin/test.sh`.
- Any edit: run `intersect doctor`.

Tool-owned config is exclusive under `tools/`: Claude may edit `tools/claude/**`, Codex may edit `tools/codex/**`, and Gemini may edit `tools/gemini/**`. Do not edit another CLI's `tools/<tool>/` files unless the user explicitly asks for that config change. Shared content under `core/`, docs, and scripts is cross-tool.

Do not edit `.claude/settings.local.json` (gitignored, machine-local). Within `tools/codex/config.toml`, avoid editing `[projects.*]`, `[marketplaces.*]`, or `[tui.*]`; Codex re-creates those per machine and they should not travel.

## Adding new content

Fork the repo, edit files in your fork. Edits flow through the symlinks immediately, so the next CLI session picks them up without further action. Commit and push to your fork, then `intersect update` on other machines.

For tool-specific overrides (e.g., a Claude-only behavior that shouldn't apply to Codex), add the rule to `core/claude.md` before the `@./agents.md` line. The wrapper exists to host these without polluting the universal file.

## Known limitations

- `tools/codex/config.toml` is symlinked, which means Codex CLI may write to the file (project trust entries, plugin enablement, marketplace state) and those writes propagate via git. Curate before committing if a write contains absolute paths or per-machine state that shouldn't travel.

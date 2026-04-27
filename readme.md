# Intersect

Single source of truth for AI-tool preferences shared across Claude Code, Codex CLI, and Gemini CLI. Named after [The Intersect](https://chuck.fandom.com/wiki/The_Intersect) from *Chuck*: one flash, instant download of every preference into the right place on every machine.

## Quickstart

```sh
# Installation
gh repo clone Polytonic/Intersect
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
├── agents.md                        # main preferences (loaded by all CLIs)
├── claude.md                        # Claude wrapper (top-level @imports)
├── primitives/
│   ├── personas.md                  # reviewer/expert roster
│   └── tools.md                     # claude/codex/gemini affordances
└── pipelines/
    ├── code-review.md               # multi-phase persona review
    ├── expert-consultation.md       # single specialist dispatch
    ├── competitive-implementation.md  # divergent then converge ("red/blue")
    └── cross-model-consultation.md  # Codex/Gemini second opinion

tools/                               # per-CLI machine config
├── claude/settings.json
├── codex/config.toml
└── gemini/settings.json

bin/
└── intersect                        # CLI
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

<details>
<summary><strong>Why lowercase repo files?</strong></summary>

Two reasons, one aesthetic and one technical:

1. The lowercase convention reads less like shouting.
2. Codex CLI auto-discovers project-level `AGENTS.md` files. If `Intersect/AGENTS.md` were uppercase, running Codex inside this repo would double-load it (project AGENTS.md plus the symlinked global one). Lowercase prevents the collision while the destination symlink (`~/.codex/AGENTS.md`) keeps the case Codex expects. macOS APFS is case-insensitive by default, so the collision risk exists only on case-sensitive volumes (or other OSes), but the lowercase convention costs nothing and removes the risk wherever it exists.

</details>

## Primitives and pipelines

The repo treats reusable building blocks (personas, tools) as **primitives** and composed workflows (code review, competitive implementation, etc.) as **pipelines**. `core/agents.md` is the entry point. It indexes both directories.

Adding a new pipeline: create `core/pipelines/<name>.md` describing trigger, steps, and synthesis. Reference any primitives it uses by path. Update `core/agents.md` § Pipelines to list it.

Adding a new primitive: create `core/primitives/<name>.md`. Update `core/agents.md` § Primitives to list it. Pipelines reference primitives by path.

## Tool compatibility notes

- **Claude Code** reads `~/.claude/CLAUDE.md` and resolves `@import` paths relative to the importing file. Top-level imports work reliably; transitive imports inside an imported file are less predictable, so `core/claude.md` imports `agents.md`, `primitives/personas.md`, and `primitives/tools.md` at the top level. Pipeline files load lazily (model reads them on demand).
- **Codex CLI** reads `~/.codex/AGENTS.md`. No `@import` syntax. The model reads referenced files on demand when it begins matching work.
- **Gemini CLI** reads `~/.gemini/GEMINI.md` by default. Supports `@file.md` imports (relative or absolute). Hierarchical context loading from cwd up to a trusted root.

## Verifying the setup

Three layers of verification, each catching a different kind of failure:

### 1. State (`intersect doctor`)

```sh
intersect doctor
```

Read-only inspection of current state: repo file presence, CLI install on PATH, every expected link symlink, tool availability with versions. Exits 0 when all is well, 1 when issues are found.

### 2. Logic (`test/test.sh`)

```sh
bash test/test.sh
```

Sandboxed in a temp `HOME` so it never touches your real `~/.claude` etc. Exercises the install/uninstall/link/unlink/doctor logic deterministically. Run after any change to `bin/intersect`. Exits non-zero on failure.

### 3. End-to-end with the AI tools

The most truthful check: do the CLIs actually load the symlinked configs? See [`test/test.md`](test/test.md) for the AI-runnable verification commands and the directive AI agents should follow when editing this repo.

## Adding new content

Fork the repo, edit files in your fork. Edits flow through the symlinks immediately, so the next CLI session picks them up without further action. Commit and push to your fork, then `intersect update` on other machines.

For tool-specific overrides (e.g., a Claude-only behavior that shouldn't apply to Codex), add the rule to `core/claude.md` before the `@./agents.md` line. The wrapper exists to host these without polluting the universal file.

## Known limitations

- `tools/codex/config.toml` is symlinked, which means Codex CLI may write to the file (project trust entries, plugin enablement, marketplace state) and those writes propagate via git. Curate before committing if a write contains absolute paths or per-machine state that shouldn't travel.

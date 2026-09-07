# Intersect

Single source of truth for AI-tool preferences shared across Claude Code, Codex CLI, and Gemini CLI.

## Quickstart

```sh
git clone https://github.com/Polytonic/Intersect.git
cd Intersect
./bin/intersect install
intersect link
intersect doctor
```

## Usage

```sh
intersect <command>
    doctor                diagnose CLI install, symlinks, and tool availability
    update                update this repo with git pull --ff-only
    link [TOOL...]        symlink config files into ~/.<tool>/
    unlink [TOOL...]      remove config symlinks pointing into this repo
    install [DIR]         symlink intersect into a PATH directory (default: /usr/local/bin)
    uninstall [DIR]       remove that PATH symlink
```

`TOOL` is one or more of `all`, `claude`, `codex`, `gemini`. `install` and `link` are idempotent. `uninstall` and `unlink` only touch symlinks they own.

## Layout

```text
core/
  agents.md              coordinator entry point
  workflow.md            shared lifecycle and general-worker contract
  claude.md              Claude wrapper that imports agents.md
  subagents/             coding, commit, design, research, reviewing, testing, writing

tools/
  claude/                Claude settings and statusline
  codex/config.toml      Codex settings
  gemini/settings.json   Gemini settings

bin/intersect            install, link, unlink, doctor, update CLI

test/
  cli.sh                 deterministic install/link/doctor tests
  verify-ai.sh           opt-in provider-backed AI verification
  readme.md              detailed AI verification commands
```

Use `profile:<path>` for Intersect-owned subagents. Use `workspace:<path>` for target project files. Unprefixed paths in task briefs refer to the active workspace. The active profile root is the parent directory of the loaded `core/` directory; if an agent cannot locate it, it must stop and ask.

## Symlink Map

| Symlink | Repo file |
|---|---|
| `~/.claude/CLAUDE.md` | `core/claude.md` |
| `~/.claude/settings.json` | `tools/claude/settings.json` |
| `~/.codex/AGENTS.md` | `core/agents.md` |
| `~/.codex/config.toml` | `tools/codex/config.toml` |
| `~/.gemini/GEMINI.md` | `core/agents.md` |
| `~/.gemini/settings.json` | `tools/gemini/settings.json` |

Runtime state stays in each tool's config directory. `settings.local.json` is not symlinked because it is machine-local.

## Verification

Pick the narrow check for the file you changed:

```sh
intersect doctor
bash test/cli.sh
test/verify-ai.sh codex
```

`intersect doctor` checks the installed CLI, expected symlinks, and tool availability. `bash test/cli.sh` runs deterministic CLI tests in a temp `HOME`; run it after changes to `bin/intersect`. `test/verify-ai.sh <tool>` is an optional live profile-loading diagnostic for installation, profile-root, or CLI changes. It is not a routine edit gate; keep it out of CI and pre-commit. See [`test/readme.md`](test/readme.md) for usage and limitations.

## Agent Notes

`core/agents.md` is the shared entry point. Claude starts from `core/claude.md`, which imports `core/agents.md`; Codex and Gemini link directly to `core/agents.md`. `core/workflow.md` holds the shared brief, authority, loading, verification, and return contract. Existing `profile:core/subagents/*.md` paths remain entry points and required domain cards. Workers explicitly read the shared workflow and applicable cards; the coordinator passes exact paths without copying their contents. Workers own relevant checks and docs, with fresh verification for consequential changes and targeted terminal specialists for concrete uncertainty.

For changes in this repo:

- Edits to `bin/intersect`: run `bash test/cli.sh`.
- Edits to subagent routing or the symlink map: run `bash test/cli.sh`.
- Any edit: run `intersect doctor`.

Tool-owned config is scoped under `tools/`: Claude may edit `tools/claude/**`, Codex may edit `tools/codex/**`, and Gemini may edit `tools/gemini/**`. Shared content under `core/`, docs, and scripts is cross-tool.

Within `tools/codex/config.toml`, avoid editing `[projects.*]`, `[marketplaces.*]`, or `[tui.*]`. Codex may recreate those sections per machine, and symlinked writes can propagate through git.

## Updating

Edit files in your fork. Symlinked changes apply to the next CLI session. Commit and push to your fork, then run `intersect update` on other machines.

For tool-specific overrides, add the rule to that tool's wrapper or config. For example, Claude-only behavior belongs in `core/claude.md` before the `@./agents.md` import.

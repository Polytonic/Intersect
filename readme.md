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
  agents.md              shared coordinator profile
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
test/verify-ai.sh pickup codex
test/verify-ai.sh behavior claude
test/verify-ai.sh paths claude codex gemini
```

`intersect doctor` checks the installed CLI, expected symlinks, and tool availability. `bash test/cli.sh` runs deterministic CLI tests in a temp `HOME`; run it after changes to `bin/intersect`. `test/verify-ai.sh` runs live provider checks; do not run it in CI or pre-commit. See [`test/readme.md`](test/readme.md) for the full AI verification command table.

## Agent Notes

`core/agents.md` is the shared entry point. Claude starts from `core/claude.md`, which imports `core/agents.md`; Codex and Gemini link directly to `core/agents.md`. Subagent files are runtime profiles referenced by `profile:core/subagents/*.md`; the coordinator passes those routes without copying full subagent configs into its own context. Each subagent embeds its consultation roster inline.

For changes in this repo:

- Edits to `core/`: run the matching AI verification command from [`test/readme.md`](test/readme.md).
- Edits to `bin/intersect`: run `bash test/cli.sh`.
- Edits to subagent routing or the symlink map: run `bash test/cli.sh`.
- Any edit: run `intersect doctor`.

Tool-owned config is scoped under `tools/`: Claude may edit `tools/claude/**`, Codex may edit `tools/codex/**`, and Gemini may edit `tools/gemini/**`. Shared content under `core/`, docs, and scripts is cross-tool.

Within `tools/codex/config.toml`, avoid editing `[projects.*]`, `[marketplaces.*]`, or `[tui.*]`. Codex may recreate those sections per machine, and symlinked writes can propagate through git.

## Updating

Edit files in your fork. Symlinked changes apply to the next CLI session. Commit and push to your fork, then run `intersect update` on other machines.

For tool-specific overrides, add the rule to that tool's wrapper or config. For example, Claude-only behavior belongs in `core/claude.md` before the `@./agents.md` import.

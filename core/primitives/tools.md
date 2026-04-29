# Tools

Each AI coding CLI is a primitive that pipelines can dispatch work to. They differ in reasoning style, context window, model availability, and tool affordances.

## Claude Code (`claude`)

- **Strengths**: Deep reasoning at xhigh effort. Rich tool affordances (Agent tool with subagent types, MCP servers, Skills, hooks). Persistent memory at `~/.claude/projects/<encoded-path>/memory/` when the auto-memory primitive is configured.
- **Affordances**:
  - `claude` (interactive) or `claude -p <prompt>` (non-interactive print-and-exit).
  - Agent tool with `subagent_type` for parallel work: `general-purpose`, `Explore` (read-only search), `Plan` (architecture), `claude-code-guide` (Claude-feature questions), and other custom types.
  - `@file.md` imports in CLAUDE.md (top-level reliable; transitive may not expand).
  - MCP servers extend tool surface.
- **When to dispatch**: Primary CLI on personal/home machines. Default for multi-agent reviews and parallel work. Choose for tasks needing tool diversity or deep reasoning.

## Codex CLI (`codex`)

- **Strengths**: Different reasoning style than Claude. Often more creative or risk-tolerant. Useful as cross-model second opinion.
- **Affordances**:
  - `codex` (interactive) or `codex exec "<prompt>"` (non-interactive).
  - `codex review` subcommand for built-in reviews.
  - Project-level + global AGENTS.md scope layering. **No `@import` syntax**. The model reads referenced files on demand.
  - Available models depend on account tier (inspect `~/.codex/models_cache.json`).
  - Configurable reasoning effort via `model_reasoning_effort` in `~/.codex/config.toml`.
- **When to dispatch**: Cross-model consultation, second opinion on architecture decisions. Primary CLI in environments where Claude Code is unavailable (e.g., work-mandated tooling). When running there, treat Codex as the home base; the pipelines and personas apply identically.

## Gemini CLI (`gemini`)

- **Strengths**: 1M-2M token context window. Uniquely suited to whole-codebase analysis exceeding the primary model's context.
- **Affordances**:
  - `gemini` (interactive) or `gemini -p "<prompt>"` (non-interactive).
  - `@file.md` imports in GEMINI.md (relative or absolute paths). Hierarchical context loading from cwd up to a trusted root.
  - `/memory` command writes to GEMINI.md as persistent context.
  - MCP support.
- **When to dispatch**: Whole-codebase analysis. Low-quota fallback for routine tasks.

## Composing tools

The Cross-Model Consultation pipeline (`pipelines/cross-model-consultation.md`) describes when and how to dispatch work across multiple tools simultaneously. The Code Review pipeline (`pipelines/code-review.md`) can dispatch persona reviews across tools when independence between trainings is valuable (e.g., the Security reviewer running on both Claude and Codex catches threats neither would alone).

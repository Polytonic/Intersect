# Tools

Each AI coding CLI is a primitive that pipelines can dispatch work to. They differ in reasoning style, context window, model availability, and tool affordances.

## Claude Code (`claude`)

- **Strengths**: Deep reasoning at xhigh effort. Rich tool affordances (Agent tool with subagent types, MCP servers, Skills, hooks). Persistent memory at `~/.claude/projects/<encoded-path>/memory/` when the auto-memory primitive is configured.
- **Affordances**:
  - `claude` (interactive) or `claude -p <prompt>` (non-interactive print-and-exit).
  - Agent tool with `subagent_type` for parallel work: `general-purpose`, `Explore` (read-only search), `Plan` (architecture), `claude-code-guide` (Claude-feature questions), and other custom types.
  - `@file.md` imports in CLAUDE.md (top-level reliable; transitive may not expand).
  - MCP servers extend tool surface.
- **Subagent patterns**:
  - **Explore**: Read-only codebase search. Maps to agents.md § "Delegate exploration to protect main context." Use for open-ended discovery that would otherwise pollute main context with raw results. Specify thoroughness: "quick", "medium", or "very thorough."
  - **Plan**: Software architect agent. Use to draft T3+ plan proposals when planning requires exploration (reading multiple files, surveying architecture). Keeps exploration out of main context.
  - **general-purpose**: Default for implementation, code changes, and tasks needing the full tool set. Use for persona agents in code review and competitive implementation.
  - **Worktree isolation**: `isolation: "worktree"` gives an agent its own git worktree. Use for competitive implementation (agents must not see each other's work) and speculative changes that shouldn't touch the working tree until approved.
  - **Background dispatch**: `run_in_background: true` dispatches work without blocking. Use when results aren't needed before the next step (parallel persona reviews, cross-model consultation alongside primary analysis). Foreground (default) when the agent's output informs your next action.
  - **Model selection**: `model` parameter selects reasoning depth per agent. Opus for T3+ review personas, architecture, security. Sonnet for T2 exploration and mechanical checks. Haiku for high-volume, low-stakes parallel tasks.
- **When to dispatch**: Primary CLI on personal/home machines. Default for multi-agent reviews and parallel work. Choose for tasks needing tool diversity or deep reasoning.

## Codex CLI (`codex`)

- **Strengths**: Different reasoning style than Claude. Often more creative or risk-tolerant. Useful as cross-model second opinion.
- **Affordances**:
  - `codex` (interactive) or `codex exec "<prompt>"` (non-interactive).
  - `codex review` subcommand for built-in reviews.
  - Project-level + global AGENTS.md scope layering. **No `@import` syntax**. The model reads referenced files on demand.
  - Available models depend on account tier (inspect `~/.codex/models_cache.json`).
  - Configurable reasoning effort via `model_reasoning_effort` in `~/.codex/config.toml`.
- **Memory**: Persistent memory at `~/.codex/memories/`. Stores task-scoped rollout summaries, user preferences, and reusable knowledge.
- **When to dispatch**: Cross-model consultation, second opinion on architecture decisions. Primary CLI in environments where Claude Code is unavailable (e.g., work-mandated tooling). When running there, treat Codex as the home base; the pipelines and personas apply identically.

## Gemini CLI (`gemini`)

- **Strengths**: 1M-2M token context window. Uniquely suited to whole-codebase analysis exceeding the primary model's context.
- **Affordances**:
  - `gemini` (interactive) or `gemini -p "<prompt>"` (non-interactive).
  - `@file.md` imports in GEMINI.md (relative or absolute paths). Hierarchical context loading from cwd up to a trusted root.
  - `/memory` command writes to GEMINI.md as persistent context.
  - MCP support.
- **Memory**: `/memory` command writes to `~/.gemini/GEMINI.md`.
- **When to dispatch**: Whole-codebase analysis. Low-quota fallback for routine tasks.

## Composing tools

The Cross-Model Consultation pipeline (`pipelines/cross-model-consultation.md`) describes when and how to dispatch work across multiple tools simultaneously. The Code Review pipeline (`pipelines/code-review.md`) can dispatch persona reviews across tools when independence between trainings is valuable (e.g., the Security reviewer running on both Claude and Codex catches threats neither would alone).

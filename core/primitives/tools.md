# Tools

Each AI coding CLI is a primitive that pipelines can dispatch work to. They differ in reasoning style, context window, model availability, and tool affordances.

## Claude Code (`claude`)

- **Strengths**: Deep reasoning at xhigh effort. Rich tool affordances (Agent tool with subagent types, MCP servers, Skills, hooks). Persistent memory at `~/.claude/projects/<encoded-path>/memory/` when the auto-memory primitive is configured.
- **Affordances**:
  - `claude` (interactive) or `claude -p <prompt>` (non-interactive print-and-exit).
  - Agent tool with `subagent_type` for parallel work: `general-purpose`, `Explore` (read-only search), `Plan` (architecture), `claude-code-guide` (Claude-feature questions), and other custom types.
  - `@file.md` imports in CLAUDE.md (top-level reliable; transitive may not expand).
  - TaskCreate/TaskUpdate for rendered task tracking. Use for small+ plans — provides a persistent, updatable progress view.
  - MCP servers extend tool surface.
  - SendMessage, or the runtime's equivalent continuation primitive, can continue a live agent with routed answers, peer findings, or revised constraints.
- **Subagent patterns**:
  - **Explore**: Read-only codebase search. Maps to the delegate-exploration guardrail in `core/agents.md`. Use for open-ended discovery that would otherwise pollute main context with raw results. Specify thoroughness: "quick", "medium", or "very thorough."
  - **Plan**: Software architect agent. Use to draft medium+ plan proposals when planning requires exploration (reading multiple files, surveying architecture). Keeps exploration out of main context.
  - **general-purpose**: Default for implementation, code changes, and tasks needing the full tool set. Use for persona agents in code review and competitive implementation.
  - **Worktree isolation**: `isolation: "worktree"` gives an agent its own git worktree. Use for competitive implementation (agents must not see each other's work) and speculative changes that shouldn't touch the working tree until approved.
  - **Background dispatch**: `run_in_background: true` dispatches work without blocking. Use when the coordinator can keep moving while the agent works, but still must collect checkpoint returns before synthesis or gate. Foreground (default) when the agent's output informs the next action.
  - **Model selection**: `model` parameter selects reasoning depth per agent. Opus for medium+ review personas, architecture, security. Sonnet for small exploration and mechanical checks. Haiku for high-volume, low-stakes parallel tasks. Default to the cheapest model that produces equivalent output.
- **When to dispatch**: Primary CLI on personal/home machines. Default for multi-agent reviews and parallel work. Choose for tasks needing tool diversity or deep reasoning.

## Codex CLI (`codex`)

- **Strengths**: Different reasoning style than Claude. Often more creative or risk-tolerant. Useful as cross-model second opinion.
- **Affordances**:
  - `codex` (interactive) or `codex exec "<prompt>"` (non-interactive).
  - `codex review` subcommand for built-in reviews.
  - Built-in plan tracker for rendered progress tracking. Use for small+ plans.
  - Project-level + global AGENTS.md scope layering. **No `@import` syntax**. The model reads referenced files on demand.
  - Available models depend on account tier (`codex debug models` for the live catalog).
  - Configurable reasoning effort via `model_reasoning_effort` in `~/.codex/config.toml`.
  - `send_input` / `resume_agent`, when exposed by the harness, can continue a live Codex agent with coordinator-routed answers, peer findings, or revised constraints.
  - **Model selection**: Highest available model at xhigh effort for review personas, architecture, and security. Mid-tier at default effort for mechanical checks and routine implementation. Default to the cheapest model that produces equivalent output. Run `codex debug models` for the live catalog.
- **Memory**: Persistent memory at `~/.codex/memories/`. Stores task-scoped rollout summaries, user preferences, and reusable knowledge.
- **When to dispatch**: Cross-model consultation, second opinion on architecture decisions. Primary CLI in environments where Claude Code is unavailable (e.g., work-mandated tooling). When running there, treat Codex as the home base; the pipelines and personas apply identically.

## Gemini CLI (`gemini`)

- **Strengths**: Large context window, depending on the active model. Useful for whole-codebase analysis exceeding the primary model's context.
- **Affordances**:
  - `gemini` (interactive) or `gemini -p "<prompt>"` (non-interactive).
  - `@file.md` imports in GEMINI.md (relative or absolute paths). Hierarchical context loading from cwd up to a trusted root.
  - `/memory` command writes to GEMINI.md as persistent context.
  - MCP support.
- **Memory**: `/memory` command writes to `~/.gemini/GEMINI.md`.
- **When to dispatch**: Whole-codebase analysis. Low-quota fallback for routine tasks.

## Composing tools

The Cross-Model Consultation pipeline (`core/pipelines/cross-model-consultation.md`) describes when and how to dispatch work across multiple tools simultaneously. The Code Review pipeline (`core/pipelines/code-review.md`) can dispatch persona reviews across tools when model independence is valuable (e.g., the Security reviewer running on both Claude and Codex catches threats neither would alone).

## Continuation and Routing

Portable coordination assumes agents do not message each other directly. The coordinator routes questions, checkpoint returns, peer findings, and user decisions unless a runtime-specific tool explicitly supports direct peer messaging. Direct peer messaging must not bypass coordinator synthesis, scope control, or final gate.

**Interactive sub-agents:** Use continuation primitives when available. Claude Code may expose SendMessage or an equivalent agent-continuation tool. Codex harnesses may expose `send_input` / `resume_agent`. Continue the originating agent with the routed answer and any constraints that changed.

**Non-interactive child CLIs:** `claude -p`, `codex exec`, and `gemini -p` are one-shot. Simulate collaboration through phased follow-up prompts that include the prior output, the routed answer or peer finding, and the next checkpoint or done-when criteria.

**Routing rule:** Questions that affect correctness, scope, API or data shape, user-visible behavior, dependency choice, or verification strategy must return to the coordinator. The coordinator decides whether to answer from existing context, ask the user, consult another agent, or start a follow-up phase.

## Nested Consultation

Nested consultation is read-only specialist advice requested by a worker inside an implementation brief. The worker reports the consultation decision in its return so the coordinator can audit whether the default was used, skipped, blocked, or routed.

- **Native nested agents**: Use when the runtime lets a worker spawn or continue child agents directly. The lead worker briefs each child with scope, style files, stop conditions, and read-only status, then closes children after synthesis unless an imminent follow-up will reuse context.
- **Coordinator-routed specialists**: Use when workers cannot spawn children but can ask the coordinator for a specialist. The worker returns the question, desired lens, risk if unanswered, and whether work can continue. The coordinator dispatches the specialist and routes the synthesized answer back.
- **Non-interactive child CLI follow-up**: Use for `claude -p`, `codex exec`, or `gemini -p`. The worker or coordinator runs a follow-up prompt that includes the original brief, scope, prior output, specialist lens, and expected return fields.
- **Unavailable mode**: Use when no safe dispatch primitive exists, the harness blocks dispatch, or consultation is inappropriate for the task. The return must state the concrete blocker and the risk scan used instead.

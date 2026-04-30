# Pipeline: Competitive Implementation

Parallel competing implementations to explore the solution space rather than committing to a single path upfront. Best suited for infinite-token-budget scenarios where exploration cost is cheap relative to the cost of shipping the wrong approach.

## Trigger

Judgment call. Good signals: the problem has genuine design tension (competing constraints with no obvious winner), the specification is clear enough for independent agents to implement without coordination, and the cost of exploring two paths is lower than the cost of backtracking from the wrong one. Bad signals: the implementation is straightforward, the problem is under-specified (agents will diverge on interpretation, not approach), or the token budget is constrained.

## Phase 1: Divergent implementation

Launch two or more agents in parallel, each implementing the same specification independently. Agents should not see each other's work. Assign distinct strategic constraints when useful (e.g., "optimize for readability" vs. "optimize for performance," or "functional style" vs. "imperative style") to maximize solution diversity. Each agent produces a complete, working implementation, not a sketch.

## Phase 2: Evaluation

A senior persona (Principal engineer, Staff engineer, or domain-appropriate authority from `primitives/personas.md`) reviews all implementations side by side. Evaluation criteria: correctness, maintainability, alignment with project conventions, performance characteristics, and deletability. The evaluator selects the best implementation or synthesizes a hybrid, taking the strongest elements from each.

## Phase 3: Hardening

The selected implementation goes through the standard Code Review pipeline (`pipelines/code-review.md`). Findings from rejected implementations that surfaced edge cases or failure modes feed into this phase as additional test cases.

## Synthesis

Report which implementation was selected (or how the hybrid was synthesized), what the rejected implementations contributed (edge cases, failure modes folded into tests), and any design tensions surfaced by the divergent agents that the user should weigh in on.

## Execution notes

Multiple agents can run in the same tool (Claude Agent tool with `subagent_type=general-purpose`, parallel `codex exec`, parallel `gemini -p`) or *across* tools (Claude implements one variant, Codex another) to maximize independence. See `primitives/tools.md`. The Cross-Model Consultation pipeline (`pipelines/cross-model-consultation.md`) overlaps with this when "different model" is itself the strategic constraint.

**Claude Code affordance:** use `isolation: "worktree"` for each competing agent. Worktree isolation gives each agent its own copy of the repo, enforcing the "should not see each other's work" requirement at the filesystem level. The selected implementation's worktree is returned with its branch and path; rejected worktrees are auto-cleaned.

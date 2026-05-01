# Pipeline: Cross-Model Consultation

Spawn parallel queries to other model providers when the primary model alone might be wrong, blind to a domain, or context-limited. On a paid subscription, marginal dollar cost is zero. The live constraints are quota burn, wall-clock time, and synthesis effort.

## Trigger

- Irreversible architecture decisions where being wrong is expensive.
- Security-critical code review (independent trainings catch different threat patterns).
- Stuck on debugging for more than 30 minutes.
- Validating a non-obvious technical claim before acting on it.
- Whole-codebase analysis exceeding the primary model's context window (Gemini's model-dependent large context window specifically).

## Synthesis

- Agreement across models → high confidence, proceed.
- Disagreement → don't pick a side. Identify the load-bearing assumption that produced the difference, and surface it explicitly. The disagreement is itself the finding.
- Spawn the consultation in parallel with the primary model's own analysis, not sequentially. Compare after both complete.

## When to skip

- Routine fixes, well-trodden patterns, obvious-consensus tasks. Synthesis cost outweighs the marginal value.
- Any task where you'd ignore the second opinion anyway.

## Execution notes

### Sibling CLIs

Each tool is a primitive. See `primitives/tools.md` for affordances. The "primary" CLI is whichever you are running; the others are siblings to consult. Verify availability with `which <name>` first.

- `claude -p "<prompt>"`: Anthropic's Claude Code. Strong general reasoning, broad tool affordances. Use as a sibling when running from Codex or Gemini.
- `codex exec "<prompt>"`: OpenAI's Codex CLI. Available models depend on the account tier and shift over time (`codex debug models` for the live catalog). The default model lives in `~/.codex/config.toml`.
- `gemini -p "<prompt>"`: Google's Gemini CLI. Verify the active model with `gemini --version` and the `/model` command in interactive mode. Context windows vary by model tier; check the Gemini Models page for the current limit before relying on long-context behavior.

### Model and CLI freshness

AI tooling moves fast: model names and capabilities shift on roughly a quarterly cadence. Before any high-stakes consultation, run `codex --version` / `gemini --version` and confirm the CLI's current default model. If a newer release is available, report the staleness and ask before upgrading (`brew upgrade codex gemini`); do not auto-upgrade. Do not hardcode model names in workflows. When a successor Pro-tier model ships, revisit which provider is best for which task type and update memory accordingly.

### Plan-tier routing

Read the `user_ai_plans` memory for current tier assignments before dispatching consultations. As a default:

- **Free or quota-constrained tiers** → reserve for the highest-stakes consultations only. Avoid parallel exploration, fuzzing, or volume tasks; quota burns fast.
- **Paid Pro-tier** → genuine consultation. Strong reasoning, generous quota, real second opinion. Default routing target.
- **Flash-tier or cheap models** → parallel exploration when token budgets are loose. Poor for cross-checking strong reasoning, since a weak model disagreeing is more often wrong than insightful.

### Detection

Plan tiers and quotas cannot be reliably auto-detected from outside the providers. On first use, ask once: "What plan are you on for codex / gemini?" Save the answer in the `user_ai_plans` memory and route subsequent calls accordingly. Re-ask if quota errors surface unexpectedly or if more than ~3 months have elapsed since the memory was last updated.

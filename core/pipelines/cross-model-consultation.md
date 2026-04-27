# Pipeline: Cross-Model Consultation

Spawn parallel queries to other model providers when the primary model alone might be wrong, blind to a domain, or context-limited. On a paid subscription, marginal dollar cost is zero. The live constraints are quota burn, wall-clock time, and synthesis effort.

## Available CLIs

Each tool is a primitive. See `primitives/tools.md` for affordances. Verify availability with `which <name>` first.

- `codex exec "<prompt>"` — OpenAI's Codex CLI. Available models depend on the account tier and shift over time, so inspect `~/.codex/models_cache.json` for the live catalog or run `codex` interactively to see what's exposed. The default model lives in `~/.codex/config.toml`.
- `gemini -p "<prompt>"` — Google's Gemini CLI. The current Pro tier (verify with `gemini --version` and the `/model` command in interactive mode) offers a 1M-token context window, extended to 2M for some configurations.

## Model and CLI freshness

AI tooling moves fast: model names and capabilities shift on roughly a quarterly cadence. Before any high-stakes consultation, run `codex --version` / `gemini --version`, upgrade if a newer release is available (`brew upgrade codex gemini`), and confirm the CLI's current default model. Do not hardcode model names in workflows. When a successor Pro-tier model ships, revisit which provider is best for which task type and update memory accordingly.

## When to use

- Irreversible architecture decisions where being wrong is expensive.
- Security-critical code review (independent trainings catch different threat patterns).
- Stuck on debugging for more than 30 minutes.
- Validating a non-obvious technical claim before acting on it.
- Whole-codebase analysis exceeding the primary model's context window (Gemini Pro specifically).

## When not to use

- Routine fixes, well-trodden patterns, obvious-consensus tasks. Synthesis cost outweighs the marginal value.
- Any task where you'd ignore the second opinion anyway.

## Plan-tier routing

- **Cheap plan / Flash-tier models** → parallel exploration, draft generation, fuzzing, brute-force volume tasks. Many shots, low cost per shot. Poor for cross-checking strong reasoning, since a weak model disagreeing is more often wrong than insightful.
- **Expensive plan / Pro-tier models** → genuine consultation. Strong reasoning, large context, real second opinion. Use these for the consultation itself.

## Detection

Plan tiers and quotas can't be reliably auto-detected. On first use, ask once: "What plan are you on for codex / gemini?" Save the answer as a user memory and route subsequent calls accordingly. Re-ask if quota errors surface unexpectedly.

## Synthesis

- Agreement across models → high confidence, proceed.
- Disagreement → don't pick a side. Identify the load-bearing assumption that produced the difference, and surface it explicitly. The disagreement is itself the finding.
- Spawn the consultation in parallel with the primary model's own analysis, not sequentially. Compare after both complete.

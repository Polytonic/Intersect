# Pipeline: Code Review

Multi-phase, multi-persona review. Use when asked to review code, or proactively after writing a non-trivial change.

The review answers three questions: (1) did I miss anything when writing the code, (2) what would make this code better, (3) what improvements are worth considering.

## Size gate

Match pipeline depth to change size:

- **<100 lines changed** → Phase 1 only.
- **100-500 lines changed** → Phase 1 plus Phase 2.
- **>500 lines, security-critical, migration, or public API** → full pipeline (Phase 1-3 plus iteration).

Override the gate when the change is small but high-stakes (auth changes, data migrations, public-facing copy, irreversible operations).

## Persona selection

The full persona roster lives in `primitives/personas.md`. **Default cap:** at most 3 personas per phase for routine T3 reviews. Lift the cap for the same triggers that unlock the full pipeline (security-critical work, migrations, public APIs, large diffs >500 lines, or explicit deep review request). Choose based on what the change touches; skip those that don't apply (e.g., Internationalization on a single-locale personal site, Product manager on internal tooling with a clear owner). Add task-specific personas when useful (e.g., a **migration auditor** for verification reviews, a **compatibility auditor** for public API changes). **Chaos Monkey QA** is always included when there is a user-facing surface.

## Phase 1: Individual review

Launch one agent per persona in parallel. Each reviews independently without seeing other agents' findings. One persona = one agent, do not batch multiple reviewers into a single agent. Individual agents think deeper within their specialty.

## Phase 2: Paired critics

For each Phase 1 agent, launch a same-specialty critic in parallel. A TypeScript critic spot-checks the TypeScript expert, a security critic spot-checks the security reviewer, and so on. Each critic challenges false positives, evaluates whether findings are genuinely actionable, and flags anything its pair missed. Domain-matched critics catch bad advice a generalist critic wouldn't.

## Phase 3: Cross-review

Every participant from Phases 1 and 2 reviews one peer's work, paired by hierarchy or adjacent expertise. Examples: Principal reviews Staff, Staff reviews New grad (seniority chain); Language expert reviews Framework expert when the framework is written in that language; Security reviews the markdown/renderer expert when user content flows through it (adjacent domain). Developer profile reviews everyone as the compliance gate. Build the cross-review matrix explicitly before launching so pairings are deliberate, not ad hoc. Critics are participants too.

## Synthesis

After Phase 3, consolidate all findings into a single summary categorized as **Fix now**, **Fix before deploy**, and **Nice to have**. Show everything in each category, do not cap or constrain the list. For each finding, indicate which agent(s) raised it (e.g., "Principal engineer + Python expert flagged this"). Organize findings against the three review goals: *missed things* (correctness gaps, regressions), *quality improvements* (maintainability, preferences-file compliance), *process feedback* (observations on how the review itself went, to fold back into agents.md).

## Iteration

Apply fixes from consensus findings, then repeat Phases 1-3. **Default cap:** two iteration rounds. After two rounds, ask the user before running another. A round terminates when every participant reports "no new findings" unprompted. If a persona has zero findings across two consecutive rounds, drop it from subsequent rounds.

## Execution notes

- Tool affordances for parallel persona dispatch: see `primitives/tools.md`. Claude Code uses the Agent tool with subagent types; Codex CLI uses parallel `codex exec` invocations or Codex Cloud; Gemini uses parallel `gemini -p` invocations. The pattern is the same regardless of mechanism.
- Instruct all agents to think deeply and thoroughly, using as many tokens as needed.
- Test empirically when possible (e.g., remove cargo-culted values and verify the code still works).
- Shared context (scope, files changed, diff stat) should be written once and referenced by all agents, not re-discovered per agent.

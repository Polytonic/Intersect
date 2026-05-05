# Pipeline: Code Review

Multi-phase, multi-persona review. Quick Review fires automatically after any code change. The formal pipeline (Phase 1+) fires proactively after medium+ changes, or when explicitly requested.

The review answers three questions: (1) did the implementation miss anything, (2) what would make this code better, (3) what improvements are worth considering.

## Scope gate

Match pipeline depth to the change's scope and blast radius per Task Triage:

- **Small scope, low blast radius** → Quick Review (see below).
- **Medium scope or elevated blast radius** (touches shared utilities, public interfaces, data models) → Phase 1 plus Phase 2.
- **Large scope or high blast radius** (security-critical, migration, public API, cross-cutting, irreversible) → full pipeline (Phase 1-3 plus iteration).

Blast radius overrides scope per `core/agents.md` Task Triage.

## Quick Review

Automatic after any small-scope code change. The goal is fast specialist feedback without ceremony.

- Pick the single most relevant persona for the change.
- For implementation work, dispatch the reviewer when the runtime provides a dispatch primitive. If dispatch is unavailable or blocked, report that constraint in the closeout instead of silently substituting local implementation review.
- For read-only review or advisory work with no workspace modification, the coordinator may use the relevant specialist lens in its own reasoning.
- Fold findings into the change summary. No separate review phase.
- Name the specialist lens only when it affected the result or explains a tradeoff.
- Escalate to Phase 1 if the review surfaces uncertainty that would change the recommendation.
- One pass, no iteration.

## Persona selection

The full persona roster lives in `core/primitives/personas.md`. **User lens is mandatory for every review or discussion task.** **Default cap:** at most 3 personas per phase for routine medium reviews, not counting the user lens or coordinator profile gate. Lift the cap for the same triggers that unlock the full pipeline (security-critical work, migrations, public APIs, large-scope diffs, high-blast-radius changes, or explicit deep review request). Choose based on what the change touches; skip those that don't apply (e.g., Internationalization on a single-locale personal site, Product manager on internal tooling with a clear owner). Add task-specific personas when useful (e.g., a **migration auditor** for verification reviews, a **compatibility auditor** for public API changes). **Chaos Monkey QA** is always included when there is a user-facing surface.

## Phase 1: Individual review

Launch one agent per persona in parallel. Each reviews independently without seeing other agents' findings. One persona = one agent, do not batch multiple reviewers into a single agent. Individual agents think deeper within their specialty.

## Phase 2: Paired critics

For each Phase 1 agent, launch a same-specialty critic in parallel. A TypeScript critic spot-checks the TypeScript expert, a security critic spot-checks the security reviewer, and so on. Each critic challenges false positives, evaluates whether findings are genuinely actionable, and flags anything its pair missed. Domain-matched critics catch bad advice a generalist critic wouldn't.

## Phase 3: Cross-review

Every participant from Phases 1 and 2 reviews one peer's work, paired by hierarchy or adjacent expertise. Examples: Principal reviews Staff, Staff reviews New grad (seniority chain); Language expert reviews Framework expert when the framework is written in that language; Security reviews the markdown/renderer expert when user content flows through it (adjacent domain). Coordinator profile reviews everyone as the compliance gate. Build the cross-review matrix explicitly before launching so pairings are deliberate, not ad hoc. Critics are participants too.

## Synthesis

After Phase 3, consolidate all findings into a single summary categorized as **Fix now**, **Fix before deploy**, and **Nice to have**. Show everything in each category, do not cap or constrain the list. For each finding, indicate which agent(s) raised it (e.g., "Principal engineer + Python expert flagged this"). Organize findings against the three review goals: *missed things* (correctness gaps, regressions), *quality improvements* (maintainability, preferences-file compliance), *process feedback* (observations on how the review itself went, to fold back into `core/agents.md`).

## Iteration

Dispatch fixes from consensus findings, then repeat Phases 1-3. **Default cap:** two iteration rounds. After two rounds, ask the user before running another. A round terminates when every participant reports "no new findings" unprompted. If a persona has zero findings across two consecutive rounds, drop it from subsequent rounds.

## Execution notes

- Tool affordances for parallel persona dispatch: see `core/primitives/tools.md`. Claude Code uses the Agent tool with subagent types; Codex CLI uses parallel `codex exec` invocations or Codex Cloud; Gemini uses parallel `gemini -p` invocations. The pattern is the same regardless of mechanism.
- Instruct all agents to think deeply and thoroughly, using as many tokens as needed.
- Test empirically when possible (e.g., remove cargo-culted values and verify the code still works).
- Shared context (scope, files changed, diff stat) should be written once and referenced by all agents, not re-discovered per agent.
- **Agent prompt construction**: Brief each persona per `core/agents.md` and the `core/pipelines/coordination.md` Worker Brief. Include the relevant style files so agents check against the actual standards: `core/styles/implementation.md` for code, `core/styles/testing.md` for tests, and `core/styles/interaction-design.md` for UI. Same shared context for all agents, distinct focus lens for each.

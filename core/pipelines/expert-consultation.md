# Pipeline: Expert Consultation

Single-specialist dispatch. Use when a question touches a specific framework, library, language feature, security concern, architecture decision, or other domain with clear subject-matter expertise. Apply the relevant specialist perspective *before* answering.

The personas (`core/primitives/personas.md`) are not just for formal code review. They are primitives any pipeline can use.

## Trigger

- Scan the question for domain signals (framework name, language feature, security topic, architecture pattern, etc.). Pick the personas that fit: framework expert, language expert, security reviewer, architect, technical writer, whichever are load-bearing for the question.
- **Speculative phrasing is a strong trigger**: "I wonder", "maybe", "perhaps", "what if", "I'm thinking" are invitations for opinion. Consult the relevant specialist persona before answering, especially for design or architecture questions. This follows the `core/agents.md` communication rule that speculative phrasing asks for a recommendation.
- **User lens is mandatory** for every advisory, review, or discussion task and counts only when launched through `core/agents.md` **Dispatch Permission**.
- If the answer requires workspace modification, leave this advisory path and use the implementation delegation protocol in `core/agents.md`.

## Execution

- Launch required specialists and the User lens through `core/agents.md` **Dispatch Permission**. A pass counts only from a separate agent, child CLI, isolated worktree, or other separate runtime.
- If launch is blocked by the runtime or explicitly declined, stop, state which required specialist or User-lens pass did not run, and ask whether to proceed without it.

## Synthesis

Combine the specialist's input with project context; do not relay verbatim. Tell the user which expert(s) were consulted so they can judge the source. If specialists disagreed, surface the disagreement and the load-bearing assumption that produced it; the disagreement itself is a finding.

## When to skip

Generic non-advisory questions where no specialist would add value. Judgment call, composable primitives, not rigid script.

# Pipeline: Expert Consultation

Single-specialist dispatch. Use when a question touches a specific framework, library, language feature, security concern, architecture decision, or other domain with clear subject-matter expertise. Apply the relevant specialist perspective *before* answering.

The personas (`core/primitives/personas.md`) are not just for formal code review. They are primitives any pipeline can use.

## Trigger

- Scan the question for domain signals (framework name, language feature, security topic, architecture pattern, etc.). Pick the personas that fit: framework expert, language expert, security reviewer, architect, technical writer, whichever are load-bearing for the question.
- **Speculative phrasing is a strong trigger**: "I wonder", "maybe", "perhaps", "what if", "I'm thinking" are invitations for opinion. Consult the relevant specialist persona before answering, especially for design or architecture questions. This follows the `core/agents.md` communication rule that speculative phrasing asks for a recommendation.
- **Independent model judgment is a strong trigger** when the primary model may be wrong, context-limited, or blind to a domain. Use sibling CLIs or model-diverse agents for irreversible architecture decisions, security-critical review, debugging that has been stuck for more than 30 minutes, validating non-obvious technical claims before acting, or whole-codebase analysis that exceeds the primary model's context window.
- **User lens is mandatory** for every advisory, review, or discussion task and counts only when launched through `core/agents.md` **Dispatch Permission**.
- If the answer requires workspace modification, leave this advisory path and use the implementation delegation protocol in `core/agents.md`.

## Execution

- Launch required specialists and the User lens through `core/agents.md` **Dispatch Permission**. A pass counts only from a separate agent, child CLI, isolated worktree, or other separate runtime.
- When independent model judgment is the trigger, launch the sibling model pass in parallel with the primary analysis when the runtime permits it. Compare the outputs only after both have formed independent judgments.
- If launch is blocked by the runtime or explicitly declined, stop, state which required specialist, User-lens, or model-independent passes did not run, and ask whether to proceed without them.

## Synthesis

Combine the specialist's input with project context. Do not relay it verbatim. Tell the user which expert(s) or model families were consulted so they can judge the source. If specialists disagree, surface the disagreement and the load-bearing assumption that produced it. The disagreement itself is a finding.

## When to skip

Skip generic non-advisory questions where no specialist would add value. Skip model-independent passes for routine fixes, established patterns, tasks with obvious consensus, and decisions where the second opinion would not change the answer.

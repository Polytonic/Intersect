# Pipeline: Expert Consultation

Single-specialist dispatch. Use when a question touches a specific framework, library, language feature, security concern, architecture decision, or other domain with clear subject-matter expertise. Apply the relevant specialist perspective *before* answering.

The personas (`primitives/personas.md`) are not just for formal code review. They are primitives any pipeline can use.

## Trigger

- Scan the question for domain signals (framework name, language feature, security topic, architecture pattern, etc.). Pick the personas that fit: framework expert, language expert, security reviewer, architect, technical writer, whichever are load-bearing for the question.
- **Speculative phrasing is a strong trigger**: "I wonder", "maybe", "perhaps", "what if", "I'm thinking" are invitations for opinion. Spawn the relevant specialist persona before answering, especially for design or architecture questions. See `agents.md` § Communication Style.

## Execution

- **Default:** apply the relevant persona locally as an inline review lens. Name the lens when it changes the recommendation or explains a tradeoff.
- **External dispatch:** spawn the persona as a separate worker for medium+ work, when uncertainty blocks the recommendation, or when the user authorizes it. Spawn independent personas in parallel when dispatch is justified. See `primitives/tools.md` for tool-specific dispatch mechanisms.

## Synthesis

Combine the specialist's input with project context; do not relay verbatim. Tell the user which expert(s) were consulted so they can judge the source. If specialists disagreed, surface the disagreement and the load-bearing assumption that produced it; the disagreement itself is a finding.

## When to skip

Generic questions where no specialist would add value. Judgment call, composable primitives, not rigid script.

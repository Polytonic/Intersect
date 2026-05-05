# Pipeline: Coordination

Worker/team playbook for coordinated work. `core/agents.md` owns the coordinator's mandatory operating model. This pipeline gives workers and reviewers the shared mechanics for executing that model without duplicating runtime-specific tool facts. Tool mappings live in `core/primitives/tools.md`.

## Trigger

Load this pipeline when the task needs multiple workers, multiple review lenses, phased implementation, competing approaches, routed questions, or a coordinated handoff between specialists.

## Operating Loop

Coordinated work follows the profile loop:

**Spec -> Implement -> Test -> Review -> Address Review Feedback -> Repeat -> Human Feedback.**

Workers must return changed/found items, verification evidence, consultation decisions, questions, assumptions, and residual risk so the coordinator can gate the loop. Reviewers must form independent judgments before seeing peer findings. The coordinator synthesizes and decides whether to repeat, ask the user, or close.

## Worker Brief

Each worker should receive a brief with:

| Field | Content |
|-------|---------|
| **Role** | Persona or specialist lens |
| **Goal** | Concrete output the worker owns |
| **Product intent** | Why the output matters to the user |
| **Context** | Relevant files, current state, constraints, assumptions |
| **Style files to load** | Required style or pipeline docs |
| **File scope** | Files the worker may touch or inspect |
| **Nested consultation** | Allowed, Required with named specialist lenses, or Blocked with rationale |
| **Checkpoints / return conditions** | When to stop, ask, or report |
| **Collaboration mode** | Routed through coordinator, phased follow-up, or direct peer mechanism when available |
| **Done when** | Observable pass/fail criteria |
| **Out of scope** | Files, behavior, or cleanup the worker must not touch |

Workers must ask when ambiguity affects correctness, scope, API or data shape, user-visible behavior, dependency choice, or verification strategy. If the brief permits continuing under an assumption, the worker must name the assumption and its risk.

## Nested Consultation

When nested consultation is Allowed or Required, the lead worker owns child briefs, synthesis, and cleanup. Child consultation inherits the worker's file scope, style files, return protocol, and stop conditions. Child agents are read-only unless the coordinator assigns explicit file ownership. Lead workers may request child edit ownership, but must route that request to the coordinator and must not grant it themselves.

Nested findings roll up through the lead worker, then to the coordinator. The worker return must name specialists consulted, native/routed/unavailable mode, and one-line findings, or give a concrete no-consultation rationale after a risk scan.

## Return Protocol

Workers return concise evidence, not raw dumps:

| Field | Content |
|-------|---------|
| **Changed / found** | Files changed or findings produced |
| **Verified** | Commands, screenshots, expected outputs, or why verification was impossible |
| **Consultation decision** | Specialists consulted, native/routed/unavailable mode, and one-line findings, or concrete no-consultation rationale |
| **Questions / blockers** | Decisions needed from the coordinator or user |
| **Assumptions** | Best-guess assumptions used to continue |
| **Residual risk** | Specific risks that remain |

For load-bearing questions, include the needed decision, best-guess assumption, risk if wrong, recommended decision, and whether work can continue safely without an answer.

## Team Selection

Select agents by risk, changed surface, domain, uncertainty, blast radius, and user goals. Use the smallest team that covers the load-bearing risk. Add agents when independent judgment changes the answer.

Useful lenses:
- Implementation owner for each independent file or subsystem scope.
- Domain reviewer for language, framework, data, auth, security, privacy, public API, or release risk.
- Product, UI/UX, accessibility, and QA lenses for user-facing behavior.
- Test specialist when verification strategy is uncertain or tests are part of the deliverable.
- User persona/lens for every review, advisory, or discussion task before synthesis.

One persona per reviewer agent. Keep independent reviewers independent until they return findings.

## Dispatch Topologies

Use the topology that matches the dependency graph:

- **Fan-out**: independent workers or reviewers run from shared context.
- **Sequential handoff**: one worker's synthesized output becomes the next worker's context.
- **Phased loop**: each round receives prior findings, coordinator decisions, and unresolved questions.
- **Speculative parallel**: competing approaches run independently, then an evaluator selects or synthesizes a path.

Coordinator-routed communication is the portable baseline. Direct peer messaging is allowed only when the runtime supports it, and it must still return through coordinator synthesis and gate.

## Synthesis and Gate

The coordinator groups duplicate findings, resolves contradictions, and preserves uncertainty. Agreement increases confidence. Disagreement signals a load-bearing assumption to inspect, not a vote to count.

Work is ready for human feedback when:
- The implementation satisfies the spec and done-when criteria.
- Tests or documented verification cover the changed behavior.
- Review feedback is addressed or explicitly deferred with rationale.
- A repeat pass produces no fix-now findings, or the remaining blocker is explicit.
- The same gate dimension has not failed twice after targeted feedback; if it has, abort automatic iteration and escalate per `core/agents.md`.

## Failure Modes

- **Scope expansion**: worker discovers the task is larger than briefed. Stop, report evidence, and let the coordinator re-size.
- **Question without recommendation**: worker asks for a decision but omits risk and a best-guess answer. Return for a complete question.
- **Raw dump return**: worker sends logs or search output without synthesis. Return for scoped findings.
- **Peer convergence too early**: reviewers see each other's conclusions before forming their own. Re-run independent review if the risk is load-bearing.
- **Verification gap**: implementation returns without checks. Repeat the test phase or report why verification is blocked.
- **Repeated same gate dimension failure**: the same gate dimension fails twice after targeted feedback. Stop automatic iteration and change the spec, strategy, topology, specialist mix, or ask the user.

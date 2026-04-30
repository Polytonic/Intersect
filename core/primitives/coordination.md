# Coordination

Portable primitives for multi-agent work. These patterns describe *what* the coordinator does; `primitives/tools.md` maps each pattern to tool-specific dispatch mechanisms.

## Coordinator Role

The profile holder (the main agent loaded with `agents.md`) is the coordinator. Sub-agents do the work; the coordinator plans, dispatches, synthesizes, and gates quality. The profile's Core Contract, verification discipline, and quality bar are the gate criteria — this is what makes the team an extension of the user's judgment rather than a generic multi-agent system.

**Coordinator responsibilities:**
1. **Scope** — understand the task, assign a tier, identify what expertise it needs
2. **Compose** — select personas and form the team (see Team Composition)
3. **Brief** — provide each sub-agent with role, shared context, constraints, and done-when criteria
4. **Dispatch** — launch sub-agents using the appropriate pattern (see Dispatch Patterns)
5. **Synthesize** — consolidate sub-agent outputs into a coherent result (see Synthesis Patterns)
6. **Gate** — verify the result against the profile before presenting to the user
7. **Iterate** — send work back when it doesn't meet the bar, with specific feedback

**What the coordinator does NOT do:**
- Implementation work that a sub-agent could handle (trivial work or faster-to-do-inline is the exception)
- Open-ended exploration (delegate to search-focused agents)
- Hold raw search results or file contents beyond what synthesis requires

**Context discipline:** The coordinator's context is the scarce resource. Sub-agents return scoped findings, not raw dumps. The coordinator holds synthesis state; sub-agents hold raw work.

## Team Composition

Select the team based on what the task touches, not a fixed roster. The persona roster lives in `primitives/personas.md`; this section defines *when* and *how many* to activate.

**Sizing heuristic:**
- **Trivial**: coordinator alone. No dispatch overhead.
- **Small**: coordinator + 0-1 specialist. Self-check before presenting; dispatch implementation to a cheaper model when the task is well-specified.
- **Medium**: coordinator + 2-4 specialists. Solicit second opinions from specialist sub-agents.
- **Large**: full team with phases. Decompose into sub-tasks first; each sub-task gets its own team composition.

**Selection signals** — which personas activate depends on what changed:
- Languages in the diff: language expert(s)
- Framework imports or config: framework expert(s)
- User-facing surface: UI/UX designer, accessibility specialist, Chaos Monkey QA
- Data schema or storage: data integrity reviewer
- Auth, crypto, or trust boundaries: security reviewer
- Public API: compatibility auditor, architect
- Tests touched or required: test architect
- Always (when team is dispatched): developer profile as compliance gate

**Cap:** 3-4 agents per parallel dispatch for routine work. Lift the cap for security-critical changes, migrations, public APIs, or large diffs (>500 lines).

## Dispatch Patterns

**Parallel fan-out:** Launch N agents simultaneously, each with an independent brief. Use when agents don't need each other's outputs. Default for review phases and competitive implementation.

**Sequential handoff:** Agent A produces output; coordinator reviews and passes relevant findings to Agent B. Use when later work depends on earlier results (architect defines structure, then implementer builds it).

**Phased:** Multiple rounds of fan-out with synthesis between rounds. Phase N+1 agents may receive Phase N findings. Use for iterative review (code review with cross-review rounds).

**Speculative parallel:** Launch multiple agents on the same task with different constraints or strategies. Compare outputs; select or synthesize the best. Use for competitive implementation and design exploration.

## Briefing Protocol

Brief each sub-agent as a colleague entering cold:

1. **Role**: which persona they embody and what they focus on
2. **Shared context**: the task, the diff, relevant files, project constraints
3. **Profile rules**: applicable rules from `agents.md` that the sub-agent must follow
4. **Done-when**: what a complete output looks like

One persona per agent. Batching multiple reviewers into a single agent produces shallower analysis than independent agents who must each form their own assessment.

## Synthesis Patterns

How the coordinator consolidates sub-agent outputs:

**Categorized findings** (review): Group by severity (fix now / fix before deploy / nice to have) with attribution (which agent flagged each). Discard duplicates; resolve contradictions.

**Winner selection** (competitive): Compare implementations against explicit criteria. Select the best or synthesize a hybrid. Rejected implementations contribute edge cases as additional tests.

**Agreement/disagreement** (consultation): Agreement signals high confidence, proceed. Disagreement signals a load-bearing assumption that needs surfacing. Present both arguments; don't break ties by vote.

**Scoped finding** (exploration): Sub-agent returns a bounded answer to a specific question. The coordinator incorporates it into the larger synthesis.

## Quality Gate

The coordinator verifies all sub-agent output against the profile before presenting to the user. The gate is the profile's quality bar applied consistently.

**Gate checks:**
- Does the output meet the verification standard? (Core Contract: verification is the highest-leverage action)
- Does it match local conventions? (Core Contract: match local conventions first)
- Is the scope tight? (Core Contract: keep scope tight)
- Would the user's quality bar accept this? (Working Style: fanatical bar for detail)
- Does it satisfy the task's done-when criteria?

**Iteration:** When output fails the gate, send it back with specific feedback: what failed, why, and what "passing" looks like. Re-brief the sub-agent rather than re-doing the work.

**Terminal condition:** Work passes the gate when no remaining finding would change the coordinator's recommendation. "No new findings from any agent" across one full iteration.

## Delegation Protocol

Structured communication between sub-agents and coordinator:

**Escalation**: Sub-agent flags "I need specialist input on X." Coordinator decides whether to dispatch an additional agent or handle it.

**Handoff**: Sub-agent produces partial work and signals that different expertise is needed to continue. Coordinator briefs the next agent with partial output as context.

**Challenge**: Sub-agent disagrees with another's finding. Coordinator surfaces both arguments and resolves, or escalates to the user when the disagreement is load-bearing.

**Scope expansion**: Sub-agent discovers the task is larger than scoped. Coordinator re-sizes per Task Triage (promote only with evidence) and adjusts the team.

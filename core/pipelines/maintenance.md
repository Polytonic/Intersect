# Pipeline: Maintenance

Session-end capture and handoff. Fires at natural session breaks or when context pressure is evident — no explicit invocation required. 80% reliability is the target.

This pipeline owns `HANDOFF.md` creation, update, and removal. Session-start readers load an existing handoff, then leave lifecycle decisions to this pipeline.

## Trigger

Run when:
- The user signals wrap-up ("okay great," "let's commit," "that's all for now")
- Context feels long or prior messages are visibly being summarized
- The user mentions compacting

Do not wait to be asked.

## Step 1: Scan

Review the session history for these trigger events:

- **Repeated correction**: same behavior corrected twice. Propose a feedback memory or `core/agents.md` addition.
- **Validated judgment**: non-obvious choice accepted without pushback. Save confirmations, not just corrections.
- **Novel composition**: new primitive combination that worked — candidate for a pipeline file.
- **Recurring context**: same constraint, path, or detail appearing across sessions.
- **Stale memory hit**: recalled memory turned out wrong or outdated. Update or remove it.
- **External tooling drift**: CLI, dependency, or model version differs from what's documented.
- **Capability ratchet**: model upgrade makes an existing rule obsolete. Remove or demote.
- **Plan/subscription drift**: quota or auth error, subscription change, or >3 months since last verification.

For each found, draft a candidate capture:

- **Type**: which trigger (repeated correction, validated judgment, etc.)
- **Evidence**: quote or summarize the relevant exchange
- **Proposed action**: exact memory write (with frontmatter) or `core/agents.md` diff

Collect all candidates before presenting — surface them at once, not one at a time. For long sessions (context visibly summarized or >50 exchanges), delegate the scan to a sub-agent to keep main context clean for the synthesis and presentation steps.

## Step 2: Present Candidates

For each candidate:

> **[Trigger type]** — [one-line description]
> Write to: [memory / core/agents.md / both]
> [Exact proposed text or diff]

Ask for approval, skip, or edit on each. For memory writes, check `MEMORY.md` for an existing entry to update before creating a new file.

## Step 3: Write Approved Items

**Memory** (tool-specific; see `core/primitives/tools.md` for each tool's memory mechanism):
- Write to the active tool's memory store with appropriate metadata
- Check for existing entries to update before creating new ones

**core/agents.md changes**:
- Dispatch the exact approved diff under the `core/agents.md` implementation protocol
- Propose a commit following commit practices

## Step 4: Write HANDOFF.md

Create, update, or remove `HANDOFF.md` in the current working directory under the active role's write protocol. Add `HANDOFF.md` to `.gitignore` if not already present. If an existing handoff has been fully consumed and no pending item remains, delete it during this step; otherwise update it in place.

The file should have five sections:

**Context** — one paragraph: what this session was about and why.

**Changes Made** — bulleted list of files changed and decisions taken, each with a brief rationale.

**Pending Items** — unfinished work, deferred decisions, open questions.

**Captured This Session** — what was written to memory or `core/agents.md`, so the next session knows what has already been processed.

**Next Steps** — concrete suggested starting point for the next session.

## Step 5: Prompt to Compact

Once HANDOFF.md is written:

> "HANDOFF.md written. Ready to compact when you are."

Do not compact automatically.

## Periodic Audit

Separately from session-end capture, periodically (every ~10 sessions or on request) audit memory for staleness, contradictions, and items that have graduated from feedback to assumed default. This is a different operation from the session-end scan — it reviews accumulated memory across sessions, not events within the current one.

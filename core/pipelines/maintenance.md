# Pipeline: Maintenance

Session-end capture and handoff. Fires at natural session breaks or when context pressure is evident — no explicit invocation required. 80% reliability is the target.

## Trigger

Run when:
- The user signals wrap-up ("okay great," "let's commit," "that's all for now")
- Context feels long or prior messages are visibly being summarized
- The user mentions compacting

Do not wait to be asked.

## Step 1: Scan

Review the session history for the trigger events listed in `agents.md § Maintenance`. For each found, draft a candidate capture:

- **Type**: which trigger (repeated correction, validated judgment, etc.)
- **Evidence**: quote or summarize the relevant exchange
- **Proposed action**: exact memory write (with frontmatter) or agents.md diff

Collect all candidates before presenting — surface them at once, not one at a time. For long sessions (context visibly summarized or >50 exchanges), delegate the scan to a sub-agent to keep main context clean for the synthesis and presentation steps.

## Step 2: Present Candidates

For each candidate:

> **[Trigger type]** — [one-line description]
> Write to: [memory / agents.md / both]
> [Exact proposed text or diff]

Ask for approval, skip, or edit on each. For memory writes, check `MEMORY.md` for an existing entry to update before creating a new file.

## Step 3: Write Approved Items

**Memory** (tool-specific; see `primitives/tools.md` for each tool's memory mechanism):
- Write to the active tool's memory store with appropriate metadata
- Check for existing entries to update before creating new ones

**agents.md changes**:
- Apply the exact approved diff
- Propose a commit following commit practices

## Step 4: Write HANDOFF.md

Write to the current working directory. Add `HANDOFF.md` to `.gitignore` if not already present.

The file should have five sections:

**Context** — one paragraph: what this session was about and why.

**Changes Made** — bulleted list of files changed and decisions taken, each with a brief rationale.

**Pending Items** — unfinished work, deferred decisions, open questions.

**Captured This Session** — what was written to memory or agents.md, so the next session knows what has already been processed.

**Next Steps** — concrete suggested starting point for the next session.

## Step 5: Prompt to Compact

Once HANDOFF.md is written:

> "HANDOFF.md written. Ready to compact when you are."

Do not compact automatically.

## Periodic Audit

Separately from session-end capture, periodically (every ~10 sessions or on request) audit memory for staleness, contradictions, and items that have graduated from feedback to assumed default. This is a different operation from the session-end scan — it reviews accumulated memory across sessions, not events within the current one.

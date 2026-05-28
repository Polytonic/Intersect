# AI Tool Verification

See [readme.md § Agent Notes](../readme.md#agent-notes) for the directive that pairs with this verification table.

`test/verify-ai.sh` is the executable live check. It runs provider-backed smoke checks from a temp directory outside this repo, so it proves cross-project pickup of the linked global config without adding network calls to `test/cli.sh`.

```sh
test/verify-ai.sh
test/verify-ai.sh behavior
test/verify-ai.sh pickup codex
test/verify-ai.sh behavior claude
test/verify-ai.sh paths claude codex gemini
```

With no tool arguments, `test/verify-ai.sh` detects the current CLI from explicit runtime environment markers and runs only that tool. If it does not detect exactly one current CLI, it prints usage and exits 2. Cross-tool diagnostics require explicit tool names, for example `test/verify-ai.sh pickup claude codex gemini`.

`pickup` checks whether each selected CLI loads the global config. `behavior` sends a synthetic profile-recognition and evidence-contract prompt that forbids tools, file inspection, commands, subagents, agents, and workspace changes. It is not a full delegation execution test. The script passes only when the response satisfies mechanical assertions for the current 11-field brief template, the ask-first conflict rule, subagent return fields, delegation manifest evidence, profile-load evidence, verification evidence, separate consultant launch evidence or a blocker when the runtime cannot launch a separate consultant, blocker and residual-risk evidence, Domain gates, All work, required process steps, Commit state-machine/message rules, `User lens`, `same dimension`, and `fails twice`.

`paths` creates a workspace decoy at `core/agents.md`. It asks for the first H1 in `profile:core/agents.md` and fails if the answer resolves the decoy instead of the profile file. It does not ask the coordinator to read subagent configs.

`test/cli.sh` includes deterministic profile-contract checks. They assert that every `core/subagents/*.md` file has a `core/agents.md` profile route, that profile routes resolve to existing files with readable first-line H1 values, and that `core/agents.md` preserves ask-first conflicts, evidence-backed coordinator gates, Domain gates, and All work; every subagent profile keeps profile-load as a top execution gate while the return protocol preserves manifest, separate consultant launch, verification, blocker, and residual-risk evidence; stale consultation exceptions stay absent; the Coding profile preserves ask-first blocker gates plus changed-surface consultant selection, Staff engineer fallback, and separate launch directive; and the Commit profile preserves its state machine, Title Case title rule, required message body, copy-editor gate, and separate push confirmation.

The `test/verify-ai.sh` checks call live providers. Keep them manual; do not run them in CI or pre-commit unless the user explicitly approves live provider calls for that gate. Auth state, session-directory access, sandbox permissions, and provider outages can fail the run before policy behavior is tested. The script classifies auth/login, permission/session-state, timeout, missing marker/assertion, and command-exit failures where practical. On failure, logs in the printed log directory hold the raw CLI output, and the tested temp project is preserved separately. On full success, both directories are removed.

The table below keeps the manual commands for targeted pickup checks. Run each command in a fresh session and check the output matches the expected value. Close paraphrase is fine for these manual pickup commands only. `test/verify-ai.sh` uses mechanical assertions. Skip rows for CLIs you don't use.

## Commands

| Tool | Command | Expected |
|---|---|---|
| Claude | `claude -p "H1 of your global preferences file?"` | `# Coordinator` |
| Claude | `claude -p "First persona in the Consultation roster of profile:core/subagents/coding.md?"` | `Principal engineer` |
| Claude | `claude -p "First H1 in profile:core/agents.md?"` | `Coordinator` |
| Codex | `codex exec "First H1 in ~/.codex/AGENTS.md, no preamble"` | `# Coordinator` |
| Codex | `codex exec "First persona in the Consultation roster of profile:core/subagents/coding.md, no preamble"` | `Principal engineer` |
| Codex | `codex exec "First H1 in profile:core/agents.md, no preamble"` | `Coordinator` |
| Gemini | `gemini -p "H1 of ~/.gemini/GEMINI.md"` | `# Coordinator` |
| Gemini | `gemini -p "First persona in the Consultation roster of profile:core/subagents/coding.md"` | `Principal engineer` |
| Gemini | `gemini -p "First H1 in profile:core/agents.md?"` | `Coordinator` |

## Manual Live Smoke Check

Run this provider-backed prompt through an installed CLI (`claude -p`, `codex exec`, or `gemini -p`), or use `test/verify-ai.sh behavior <tool>`. Expected: the answer includes the 11 brief fields, the ask-first conflict rule, subagent return fields, evidence requirements for delegation, profile loading, verification, consultation, blockers, and residual risk, a consultation policy naming the `User lens`, separate consultant launch requirement, no-self-authored-answer rule, consultant brief contents, and blocker when separate consultant launch cannot be performed, Domain gates, All work, Commit routing and message gates, and escalation criteria containing `same dimension` and `fails twice`. This is a synthetic contract check, not proof that the CLI can execute a full delegation workflow.

```text
Synthetic profile-recognition and evidence-contract check only. This is not an
active implementation request and not a real coordinator workflow.

Do not use tools, inspect files, run commands, launch subagents or agents, or
modify workspace state. Do not describe actions as completed. Produce a compact
static template that demonstrates the required labels, evidence, and phrases.

Return only these sections:
- Brief fields
- Subagent evidence
- Consultation policy
- Domain gates
- Commit policy
- Escalation criteria

Required exact words/phrases:
- When requirements are unclear
- instructions conflict
- stop and ask before routing or acting
- Role
- Goal
- Task
- Context
- Scope
- Inputs
- Outputs
- Examples
- Done when
- Downstream
- Reasoning
- Changed/found
- Verified
- Consulted
- Questions/blockers
- Residual risk
- Profile Load
- Before role work, read the exact resolved absolute profile path from the brief.
- delegation manifest
- profile route
- profile root
- resolved absolute profile path
- loaded config path
- read status
- observed profile header
- observed profile marker
- model/effort if known
- isolation/context mode
- agent id if known
- external-service permission state
- commands
- inspected sources
- exact results
- skipped gates with reasons
- delegated agent id
- separate-session identifier
- launch a separate consultant agent or session
- Do not write the consultant answer yourself
- consultant brief
- question or scope
- relevant files or context
- expected return
- prompt scope
- changes made in response
- why none were made
- If the runtime cannot launch a separate consultant
- blocked reason
- evidence, owner, and next action
- acceptable or blocked
- Domain gates
- Do not invent domain-specific acceptance criteria after dispatch
- All work
- Each downstream subagent received and addressed previous subagent's output
- required process steps
- route commit requests through the Commit profile
- Commit profile
- State Machine
- Title Case
- required body
- Copy editor
- Push Gate
- separate explicit confirmation
- User lens
- same dimension
- fails twice

Every subagent brief must include these fields in order: "Role:", "Goal:",
"Task:", "Context:", "Scope:", "Inputs:", "Outputs:", "Examples:",
"Done when:", "Downstream:", and "Reasoning:".
Every subagent profile must include a top "Profile Load" section with "Before
role work, read the exact resolved absolute profile path from the brief."
Every subagent return must include "Changed/found:", "Verified:", "Consulted:",
"Questions/blockers:", and "Residual risk:" fields.
"Changed/found:" must begin with a delegation manifest naming profile route,
profile root, resolved absolute profile path, loaded config path, read status,
observed profile header or observed profile marker, model/effort if known,
isolation/context mode, agent id if known, and external-service permission
state. Its first evidence must include "Loaded config: <resolved absolute
profile path>", "Read status: success", and "Observed profile header:" or
"Observed profile marker:" from the loaded file.
"Verified:" must name commands, inspected sources, exact results, and skipped
gates with reasons. "Consulted:" must name a delegated agent id or
separate-session identifier, prompt scope, findings, and changes made in
response or why none were made. It must require the worker to launch a separate
consultant agent or session, avoid writing the consultant answer itself, and
send a consultant brief naming the persona, question or scope, relevant files or
context, and expected return. If the runtime cannot launch a separate
consultant, it must report a blocked reason.
"Questions/blockers:" must state None or list each blocker with evidence, owner,
and next action. "Residual risk:" must state None or name uncertainty, evidence,
and why it is acceptable or blocked.
Consultation policy must name the User lens, required process steps,
separate consultant launch requirement, no-self-authored-answer rule, consultant
brief contents, and the blocker when separate consultant launch cannot be
performed.
Domain gates must state not to invent domain-specific acceptance criteria after
dispatch. All work must state that each downstream subagent received and
addressed previous subagent output.
Commit policy must route commit requests through the Commit profile, require the
State Machine, Title Case title, required body, Copy editor consultation, and
Push Gate with separate explicit confirmation. Escalation criteria must include
the exact phrases "same dimension" and "fails twice".
```

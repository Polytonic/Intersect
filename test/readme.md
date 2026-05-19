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

`pickup` checks whether each selected CLI loads the global config. `behavior` sends a synthetic profile-recognition and format prompt that forbids tools, file inspection, commands, subagents, agents, and workspace changes. It is not a full delegation execution test. The script passes only when the response satisfies mechanical assertions for the current 11-field brief template, subagent return fields, `User lens`, `same dimension`, and `fails twice`.

`paths` creates a workspace decoy at `core/agents.md`. It asks for the first H1 in `profile:core/agents.md` and fails if the answer resolves the decoy instead of the profile file. It does not ask the coordinator to read subagent configs.

These checks call live providers. Auth state, session-directory access, sandbox permissions, and provider outages can fail the run before policy behavior is tested. The script classifies auth/login, permission/session-state, timeout, missing marker/assertion, and command-exit failures where practical. On failure, logs in the printed log directory hold the raw CLI output, and the tested temp project is preserved separately. On full success, both directories are removed.

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

Run this provider-backed prompt through an installed CLI (`claude -p`, `codex exec`, or `gemini -p`), or use `test/verify-ai.sh behavior <tool>`. Expected: the answer includes the 11 brief fields, subagent return fields, a consultation policy naming the `User lens`, and escalation criteria containing `same dimension` and `fails twice`. This is a synthetic format check, not proof that the CLI can execute a full delegation workflow.

```text
Synthetic profile-recognition and format check only. This is not an active
implementation request and not a real coordinator workflow.

Do not use tools, inspect files, run commands, launch subagents or agents, or
modify workspace state. Do not describe actions as completed. Produce a compact
static template that demonstrates the required labels and phrases.

Return only these sections:
- Brief fields
- Subagent returns
- Consultation policy
- Escalation criteria

Required exact words/phrases:
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
- User lens
- same dimension
- fails twice

Every subagent brief must include these fields in order: "Role:", "Goal:",
"Task:", "Context:", "Scope:", "Inputs:", "Outputs:", "Examples:",
"Done when:", "Downstream:", and "Reasoning:".
Every subagent return must include "Changed/found:", "Verified:", "Consulted:",
"Questions/blockers:", and "Residual risk:" fields. Consultation policy must
name the User lens. Escalation criteria must include the exact phrases "same
dimension" and "fails twice".
```

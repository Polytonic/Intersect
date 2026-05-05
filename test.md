# AI Tool Verification

See readme.md § For AI agents working in this repo for the directive that pairs with this verification table.

`bin/verify-ai.sh` is the executable live check. It runs provider-backed smoke checks from a temp directory outside this repo, so it proves cross-project pickup of the linked global config without adding network calls to `bin/test.sh`.

```sh
bin/verify-ai.sh
bin/verify-ai.sh pickup codex
bin/verify-ai.sh behavior claude
bin/verify-ai.sh paths codex
```

`pickup` checks whether each CLI loads the global config. `behavior` checks whether each CLI follows the nested-consultation smoke prompt and passes mechanical assertions for required phrases and structure, including `Delegation tree`, `Worker briefs`, `Worker returns`, `Abort criteria`, `Nested consultation: Required`, `Nested consultation: Allowed`, `Consultation decision:`, `same gate dimension`, and `fails twice`.

`paths` creates a workspace decoy at `core/styles/interaction-design.md`. It asks for `profile:core/styles/interaction-design.md` and fails if the answer resolves the decoy instead of the profile file whose first H2 is `Interaction Design`.

These checks call live providers. Auth state, session-directory access, sandbox permissions, and provider outages can fail the run before policy behavior is tested. The script classifies auth/login, permission/session-state, timeout, missing marker/assertion, and command-exit failures where practical. On failure, logs preserved in the printed temp project path hold the raw CLI output. On full success, the temp project is removed.

The table below keeps the manual commands for targeted pickup checks. Run each command in a fresh session and check the output matches the expected value. Close paraphrase is fine for these manual pickup commands only. `bin/verify-ai.sh` uses mechanical assertions. Skip rows for CLIs you don't use.

## Commands

| Tool | Command | Expected |
|---|---|---|
| Claude | `claude -p "H1 of your global preferences file?"` | `# Coordinator Profile` |
| Claude | `claude -p "First persona under Core roster in core/primitives/personas.md?"` | `Principal engineer` |
| Claude | `claude -p "First H2 in your tools primitive?"` | `Claude Code` |
| Claude | `claude -p "First H2 in profile:core/styles/interaction-design.md?"` | `Interaction Design` |
| Codex | `codex exec "First H1 in ~/.codex/AGENTS.md, no preamble"` | `# Coordinator Profile` |
| Codex | `codex exec "First persona under Core roster in core/primitives/personas.md, no preamble"` | `Principal engineer` |
| Codex | `codex exec "First H2 in profile:core/styles/interaction-design.md, no preamble"` | `Interaction Design` |
| Gemini | `gemini -p "H1 of ~/.gemini/GEMINI.md"` | `# Coordinator Profile` |
| Gemini | `gemini -p "First H1 in core/primitives/personas.md"` | `# Personas` |
| Gemini | `gemini -p "First H2 in profile:core/styles/interaction-design.md?"` | `Interaction Design` |

## Manual Live Smoke Check

Run this provider-backed prompt through an installed CLI (`claude -p`, `codex exec`, or `gemini -p`), or use `bin/verify-ai.sh behavior <tool>`. Expected: the answer includes a delegation tree, worker briefs with the `Nested consultation` field, worker returns with the `Consultation decision` field, route modes `native`, `routed`, and `unavailable`, and abort criteria containing `same gate dimension` and `fails twice`.

```text
Plan a small implementation for a role-aware admin/settings navigation system. Do not edit files.

Return only these sections:
- Delegation tree
- Worker briefs
- Worker returns
- Abort criteria

Required exact words/phrases:
- Nested consultation
- Required
- Allowed
- Consultation decision
- native
- routed
- unavailable
- same gate dimension
- fails twice

Every worker brief must include "Nested consultation:" with Required or Allowed. Include at least one Required worker and one Allowed worker. Every worker return must include "Consultation decision:" and classify the consultation route as native, routed, or unavailable. Abort criteria must include the exact phrases "same gate dimension" and "fails twice".
```

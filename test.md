# AI Tool Verification

See readme.md § For AI agents working in this repo for the directive that pairs with this verification table.

`bin/verify-ai.sh` is the executable live check. It runs provider-backed smoke checks from a temp directory outside this repo, so it proves cross-project pickup of the linked global config without adding network calls to `bin/test.sh`.

```sh
bin/verify-ai.sh
bin/verify-ai.sh codex
```

The table below keeps the manual commands for targeted checks. Run each command in a fresh session and check the output matches the expected value. Close paraphrase is fine. These are model responses, not strict assertions. Skip rows for CLIs you don't use.

## Commands

| Tool | Command | Expected |
|---|---|---|
| Claude | `claude -p "H1 of your global preferences file?"` | `# Coordinator Profile` |
| Claude | `claude -p "First persona under Core roster in core/primitives/personas.md?"` | `Principal engineer` |
| Claude | `claude -p "First H2 in your tools primitive?"` | `Claude Code` |
| Claude | `claude -p "First H2 in your interaction-design primitive?"` | `Interaction Design` |
| Codex | `codex exec "First H1 in ~/.codex/AGENTS.md, no preamble"` | `# Coordinator Profile` |
| Codex | `codex exec "First persona under Core roster in core/primitives/personas.md, no preamble"` | `Principal engineer` |
| Codex | `codex exec "First H2 in interaction-design.md, no preamble"` | `Interaction Design` |
| Gemini | `gemini -p "H1 of ~/.gemini/GEMINI.md"` | `# Coordinator Profile` |
| Gemini | `gemini -p "First H1 in core/primitives/personas.md"` | `# Personas` |
| Gemini | `gemini -p "First H2 in your interaction-design primitive?"` | `Interaction Design` |

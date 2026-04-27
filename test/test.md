# AI Verification

End-to-end verification that the AI tools load the symlinked configs correctly. Run each command in a fresh session and check the output matches the expected value. Close paraphrase is fine, these are model responses, not strict assertions. Skip rows for CLIs you don't use.

## Commands

| Tool | Command | Expected |
|---|---|---|
| Claude | `claude -p "H1 of your global preferences file?"` | `# Developer Profile` |
| Claude | `claude -p "First persona under Core roster?"` | `Principal engineer` |
| Claude | `claude -p "First H2 in your tools primitive?"` | `Claude Code` |
| Codex | `codex exec "First H1 in ~/.codex/AGENTS.md, no preamble"` | `# Developer Profile` |
| Codex | `codex exec "First persona under Core roster in ~/.codex/AGENTS.md"` | `Principal engineer` |
| Gemini | `gemini -p "H1 of ~/.gemini/GEMINI.md"` | `# Developer Profile` |

## For AI agents working in this repo

This file is the verification checklist for end-to-end behavior. After edits to anything in `core/`, run the matching command above for the affected tool. After edits to `bin/intersect`, run `bash test/test.sh` (logic regression). After any edit, `intersect doctor` is a fast sanity check on current state.

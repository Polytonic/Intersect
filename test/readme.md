# AI Tool Verification
`test/verify-ai.sh` is an optional live diagnostic for global-preferences pickup and profile-root resolution. Use it after installation, linking, profile-root, or relevant CLI changes, or to investigate a loading problem. Ordinary policy/content edits do not require a live probe.

## Usage
Choose exactly one installed provider explicitly:

```sh
test/verify-ai.sh codex
test/verify-ai.sh claude
test/verify-ai.sh gemini
```

No argument, unknown providers, multiple arguments, and the old `pickup`, `paths`, and `behavior` interfaces fail. The script calls the selected live provider; obtain scoped permission and keep it out of CI/pre-commit. It installs nothing.

The diagnostic creates a temporary workspace containing a decoy `core/agents.md`. It asks the model for the physical global-preferences source, the resolved profile path, and its H1. An exact response must identify this checkout; prompt echoes, decoy answers, and nonzero provider exits fail. This diagnostic does not prove actual file reads, delegation, or policy execution.

## Failures And Cleanup
The timeout defaults to 90 seconds; set `INTERSECT_VERIFY_AI_TIMEOUT_SECONDS` to a positive integer to change it. A missing provider exits 127, invalid arguments/configuration exit 2, timeout exits 124, and a mismatched response exits 1. Provider failures preserve their exit status. Interruption stops the provider process group and exits 130 (INT) or 143 (TERM).

On success, the temporary directory is removed. On failure/interruption, its printed path is retained with `response.txt`, `provider.log`, and the decoy project for diagnosis. Codex uses its final-message file; Claude/Gemini use stdout. CLI-owned state, such as trusted-project entries, may persist outside this directory. Do not broadly clean user configuration.

## Deterministic Checks
`bash test/cli.sh` covers CLI/link/profile contracts and diagnostic fixtures without calling live providers. Shell syntax checks must name each script separately, for example `bash -n test/verify-ai.sh`. Agents may reuse passing results for unchanged inputs instead of repeating checks.

## Scenario Review
After policy changes, inspect these cases against the new rules. Record the resulting decisions and distinguish inspection from live execution:
- Advisory or mechanical work: delegate appropriately and self-check.
- Ordinary behavior-affecting code or multi-file policy/contracts: fresh verification.
- Dirty tree: preserve unrelated files, hunks, and existing staged work against the pre-edit baseline.
- Denied external access: report the blocked action; preserve existing grants for unaffected work.
- Commit without push: freeze scope, check cached diff and message, confirm amend separately, leave push unperformed.
- Security-critical or irreversible work: review with a different model family.
- Terminal consultation or exhausted capacity: zero descendants; report unavailable launch/close operations without retry loops.

Size measurements cover all coordinator, shared, and domain policy files against the current working-tree baseline. Report test/docs changes separately. Neither shortening nor synthetic checks establish behavioral parity, runtime enforcement, or measured latency/token savings.

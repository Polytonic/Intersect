# Pipeline: Regression Test

Run after any code-modifying change to catch breakage before declaring done. Cheap insurance: catches things that "looked right" but aren't.

## Trigger

Any task that modifies code, config, or content where the project has automated checks. Run before declaring the task complete. Skip only when there is no test surface (pure docs change in a repo with no tests).

## Phase 1: Discover

Identify what to run for the change scope:

- **Type and lint checks** (mypy, flake8, eslint, tsc, clippy, `go vet`, etc.) for any code change.
- **Unit and integration tests** in the affected modules.
- **Project-specific verifiers** (e.g., `intersect doctor`, custom health checks, end-to-end smokes).
- **AI verification commands** if the project has them (per project-local CLAUDE.md, AGENTS.md, or test.md).

Project-local files often document the right checks; read them first.

## Phase 2: Execute

Run the discovered checks. Run in parallel where they do not share state. Capture full output, not just exit codes; suppressed warnings often signal problems.

## Phase 3: Triage

Categorize each failure:

- **Regression** (passed before this change, fails now): caused by the work just done. Fix before declaring done.
- **Pre-existing failure** (unrelated to the change): note it, surface to the user, do not silently ignore.
- **Expected change** (test asserted old behavior, change intentionally alters it): update the test, do not weaken the assertion.

Do not rerun until green. A flaky test passing on retry is not the same as a fixed test; investigate the flake.

## Synthesis

Report:

- Pass/fail counts per check type.
- What failed and why (regression / pre-existing / expected).
- If regressions remain, the task is not done; return to fixing.
- If only pre-existing failures remain, the task is done but flag the pre-existing failures explicitly.

## When to skip

- Pure documentation changes in a repo with no auto-tests.
- Comment-only edits.
- Strictly cosmetic tweaks (whitespace, commit message rewording before push).

Otherwise, run.

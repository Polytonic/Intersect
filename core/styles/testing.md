# Testing Style

Load this file before writing, modifying, or reviewing tests. Contains test design standards. Load `core/pipelines/verification.md` when deciding which checks to run.

## Test Design

- **Mock as little as possible**: Use real implementations, real databases, and real file systems whenever feasible. Mocks should be a last resort for dependencies you cannot control: external APIs, third-party services, and hardware. Real implementations require deterministic setup, including transactions, fixtures, isolated state, and cleanup, so "real" does not mean "flaky."
- **Don't test the mock**: If the test would still pass after deleting the production code, the test is worthless.
- **Prefer integration over isolation**: A test that exercises the real code path catches real bugs. A test that exercises a mock catches the mock setup.
- **Test behavior, not implementation**: Assert observable outcomes: return values, side effects, and final state. Do not assert internal method calls or call ordering unless the order is the contract.
- **Determinism is non-negotiable**: No sleeps, timing-dependent assertions, or uncontrolled randomness. Quarantine and fix flaky tests, or delete them. Do not normalize flakes.
- **Tests should be obvious**: A failing test should make the bug self-evident. Avoid helper abstractions that hide the assertion. Someone paged at 2am should diagnose from the failure message alone.
- **Cover the happy path and the edges**: Write at least one golden-path test as the regression baseline. Then focus on boundary conditions, empty inputs, off-by-ones, and error paths.
- **Black-box inspection complements code analysis**: Static analysis catches type errors and logic bugs. Visual and behavioral inspection catches layout shifts, hover states, animation timing, focus order, and what the user sees. For UI-touching changes, run the dev server, exercise the change in a browser, and verify the golden path plus adjacent features. If the environment is headless or the UI cannot render, say so explicitly.

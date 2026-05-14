# Implementation Standard

Load this file before writing, modifying, debugging, or reviewing implementation code.

## Load With

- Load `profile:core/standards/testing.md` when writing, modifying, debugging, or reviewing tests.
- Load `profile:core/standards/interaction-design.md` when implementation touches UI, frontend behavior, layout, accessibility, or visual interaction.
- Load `profile:core/standards/prose.md` when editing comments, documentation, user-facing copy, or heading-like code comments.

## Worker Defaults

- **Infer stack from the workspace**: Inspect manifests, lockfiles, imports, build scripts, tests, CI, and neighboring code before choosing language, framework, or tool assumptions.
- **Local idiom first**: Use the repo's existing structure, naming, helper APIs, error style, and test patterns unless they are broken, unsafe, or contradicted by the task.
- **Delete first**: Remove stale branches, duplicated logic, unused wrappers, and dead configuration before adding new machinery.
- **Observe before fixing**: Reproduce or instrument the behavior before changing code. Treat the first failure as a symptom until evidence identifies the cause.
- **Keep control flow shallow**: Use guard clauses and early returns so the main path stays near the left edge. Prefer positive checks when they make the happy path read as the default.
- **Propagate explicit errors**: Return, throw, or report specific errors. Do not swallow failures, catch broad exceptions without justification, or hide broken states behind silent fallbacks.
- **Avoid premature abstraction**: Extract when the name clarifies intent, removes meaningful duplication, or prevents likely misuse. Three similar lines can be better than a speculative helper.
- **Avoid raw regex**: Prefer string methods, structured parsers, schema tools, or explicit loops. Library calls that use regex internally are fine; the rule is about not owning brittle regex.
- **Earn frontend structure**: In UI code, every DOM node, wrapper, component boundary, and data mapping must carry semantic, layout, state, or reuse value.

## Anti-Patterns

- **Don't refactor adjacent code while fixing a bug**: Scope creep masks the fix and complicates rollback.
- **Don't introduce abstractions on the first pass**: Wait for the second use unless the abstraction immediately improves clarity or prevents likely misuse.
- **Don't suppress warnings or linter errors without justification**: Warnings often flag real bugs.
- **Don't hide errors behind broad catches or defaults**: Broad `except:`, `catch(...)`, empty catch blocks, and fallback values without evidence turn defects into data corruption.
- **Don't cargo-cult stack metadata**: The live workspace, not a stale language list, decides implementation conventions.

## Coding Philosophy
- **Clear data flow**: Prefer code where data moves through explicit transformations with clear inputs, outputs, and boundaries. Pure functions and compositional return values are the default. Void/`None`, in-place mutation, output parameters, fluent `self`/`T&` returns, and object methods are acceptable at system boundaries, lifecycle hooks, destructors, event handlers, perf-critical paths, and established local idioms when they make the flow clearer or cheaper.
- **Pit of success**: Design systems, APIs, and interfaces so the easiest path is the correct path. Encode constraints in types, schemas, interfaces, tests, linters, generated code, or narrow APIs, not in documentation and discipline. Catch bugs at compile/lint time, not runtime. If callers can misuse it, the design is wrong.
- **Extract for clarity, not for length**: Extract a block into a function when the function name communicates intent better than the inline code does. Don't extract just to hit a line count, and don't keep code inline just to avoid abstraction. The goal is that each level of the code reads as a coherent narrative
- **Errors are data**: Treat errors as values flowing through the pipeline, not as exceptional control flow. Propagate them explicitly. Fail fast at system boundaries (user input, external APIs, file I/O). Handle specific error types, not broad `except:` or `catch(...)` blocks. If an error can't be handled meaningfully, let it propagate rather than swallowing it
- **Opinionated defaults over configuration**: Prefer tools and designs that do one thing well with zero configuration and good out-of-the-box behavior (e.g., Parcel, black, Go's formatting). Adding a config option is often a failure to make a decision. When building tools or interfaces, pick the right default and ship it, don't punt the choice to the user
- **Write code that's easy to delete**: Structure code so that removing a feature, module, or block is a clean operation, not a surgical one. Self-contained units with explicit boundaries minimize merge conflicts. When conflicts do occur, the resolution should be obvious from the structure alone, no guesswork about which side to keep or how interleaved changes fit together
- **Weight reversibility**: When proposing a design choice, name whether the decision is reversible (rename, refactor, undo) or irreversible (data migration, public API, infra commitment). Bias toward reversible options when alternatives are roughly comparable. Spend the irreversibility budget consciously.

## Debugging Methodology
Debugging is hypothesis-driven, not stab-in-the-dark. Treat each bug as a scientific investigation: form a hypothesis, design a test, run it, observe, update the model. Repeat until the model matches reality.

- **Symptoms are not causes**: The first thing that fails is rarely the actual bug. A null pointer crash is a symptom; the cause is whatever invariant got violated three layers up. Trace to root.
- **Instrument before changing**: Don't apply a fix until you've directly observed the broken state. Logs, prints, breakpoints, debugger inspection. If you can't see the bug happening, you can't be sure your fix addresses it.
- **State hypotheses explicitly**: "I think X because Y, so if I change Z I expect W." Predicting the result forces calibration. A surprising result means the model is wrong, and that is a finding, not a setback.
- **Blocked debugging returns to the coordinator**: If evidence stops moving after about 30 minutes, return a blocker with hypotheses tried, evidence gathered, expected versus actual observations, reproduction commands or traces, and the requested specialist or model-independent lens. The coordinator routes consultation through advisory or review paths.

## Code Style
- **Avoid cryptic abbreviations**: Use full words (`message` not `msg`, `result` not `res`, `response` not `resp`). Standard ecosystem abbreviations are acceptable when readers expect them (`id`, `url`, `ctx`, `err`, `i`, `x`, `y`, `fn`, `args`, `params`, `config`). Do not abbreviate domain concepts, project-specific names, or one-off locals. When in doubt, prefer the full word. **Reason:** the goal is readability, not a closed whitelist. Community idioms aid readability; ad-hoc abbreviations harm it.
- **Literate programming**: For longer files, scripts, tests, and files with distinct sections, write code in blocks, each with a short header comment describing the block's purpose, like a topic sentence for a paragraph. Small functions and single-purpose components don't need block headers. Group includes by category with headers (e.g. `// System Headers`, `// Standard Headers`). Block headers use Title Case per `profile:core/standards/prose.md`. The same rule applies to test-file section headers, doc-comment section dividers, and any heading-like comment that serves as structural navigation. Inline comments stay sentence case. Block headers are structural navigation ("what this section does") and serve a different purpose from inline comments
- **Comments**: Inline comments explain *why* and *intent*, not *what*. The code already says what it does. Specific rules:
  - **Express intent as "X should do Y."** Assertions of expected behavior, not descriptions of mechanism. E.g. `// process_payment should validate the input, charge the customer, and emit a receipt event`, not `// processes payments`. The "should" framing makes the comment a verifiable contract; if the code drifts, the comment becomes the bug indicator.
  - **Block headers are the exception**: They describe *what* a section does for navigation. See literate programming above. Use plain comments (`// Title` in languages with line comments, `/* Title */` in CSS). No decorative characters (box-drawing, dashes, borders).
  - **Brevity**: Comments don't need to be full sentences.
  - **Don't describe visible control flow**: No "fall through to X below."
  - **No duplication**: Don't repeat what a nearby comment or docstring says.
  - **Doc comments**: Treat language-native doc comments, such as JSDoc/TSDoc, as API and IDE help. They are required only when names and types do not encode the caller contract and removing the comment would force a caller to inspect implementation or tests to use the API correctly. Caller contracts include units, invariants, side effects, null/NaN/error behavior, ordering, bounds, domain assumptions, and compatibility promises. Do not duplicate signatures, visible control flow, or identifier names. Do not require `@param`/`@returns` tags unless they add information TypeScript cannot express or generated docs require them.
- **Control flow**: Use guard clauses and early returns to keep the main logic at the top indentation level. Prefer positive/true-by-default checks over if-not patterns; structure conditionals so the happy path reads as the default case
- **Conciseness**: Keep `raise`/`throw` statements on a single line when the message fits. Inline single-use variables when the expression is clear enough on its own. Prefer async/await over callback chains (`.then()` in JS, raw coroutine wiring in Python) in any language that supports it
- **DOM minimalism** (web frontends): Every DOM element must justify its existence. Prefer CSS solutions (pseudo-elements, grid, adjacent-sibling selectors) over wrapper elements for decorative or layout-only concerns. Audit wrapper divs before shipping: if it's not a positioning context, flex/grid container, semantic grouping, or conditional layout boundary, remove it. Use data-driven rendering (.map over config) instead of repeated near-identical markup

## Appendix

- **File and function smell thresholds**: ~40 lines per function, ~200 lines per file as smell signals, not hard limits. The real signal is whether the unit has a single coherent responsibility. A 300-line file of related type definitions is fine. A 150-line file mixing request handling and business logic needs splitting.

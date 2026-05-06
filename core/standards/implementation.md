# Implementation Standard

Load this file before writing or modifying code. Contains coding philosophy, debugging methodology, and code formatting rules. Load `core/standards/testing.md` when writing, modifying, or reviewing tests.

## Languages & Stack
- Primary working languages: C++, Python, TypeScript

## Coding Philosophy
- **Software is data transformation**: Programs are pipelines: data comes in, gets transformed through a series of functions, and data comes out. This is the unifying principle behind the preference for pure functions, composition, and returning values. Functions are transformations, not procedures. Design them as pipeline stages: clear input, clear output, no hidden state. This is a design mindset, not strict immutability dogma. Idiomatic mutation (returning `self` for chaining in Python, returning `T&` in C++) is fine because it serves the same goal: clear data flow through composable stages
- **Pit of success**: Design systems, APIs, and interfaces so the easiest path is the correct path. Encode constraints in types, schemas, interfaces, tests, linters, generated code, or narrow APIs, not in documentation and discipline. Catch bugs at compile/lint time, not runtime. If callers can misuse it, the design is wrong.
- **Extract for clarity, not for length**: Extract a block into a function when the function name communicates intent better than the inline code does. Don't extract just to hit a line count, and don't keep code inline just to avoid abstraction. The goal is that each level of the code reads as a coherent narrative
- Prefer functional style over object-oriented: pure functions, transformations, composition
- **Prefer compositional return values**: Functions return values to enable chaining and composition. Void is acceptable at boundaries (event handlers, lifecycle hooks, destructors, signal handlers, command entry points) and in perf-critical paths (in-place mutation, output parameters) where allocation matters. **Reason:** Boundary code cannot meaningfully return values; the strict rule generated pointless `return self` at boundaries. Perf paths serve the same data-flow goal at lower cost.
- Avoid regular expressions; they are error-prone and hard to read. Use string methods, parsing libraries, or explicit loops instead. **Reason:** Regex accumulates complexity invisibly and resists refactoring. Library calls are fine even if internally regex-based; the rule is about not writing or maintaining raw regex.
- **Errors are data**: Treat errors as values flowing through the pipeline, not as exceptional control flow. Propagate them explicitly. Fail fast at system boundaries (user input, external APIs, file I/O). Handle specific error types, not broad `except:` or `catch(...)` blocks. If an error can't be handled meaningfully, let it propagate rather than swallowing it
- **Opinionated defaults over configuration**: Prefer tools and designs that do one thing well with zero configuration and good out-of-the-box behavior (e.g., Parcel, black, Go's formatting). Adding a config option is often a failure to make a decision. When building tools or interfaces, pick the right default and ship it, don't punt the choice to the user
- **Atomic Design** (web/UI projects): UI components follow Brad Frost's Atomic Design hierarchy (Atom → Molecule → Compound → Template → Page), with "Compound" replacing "Organism." Shared primitives (atoms/molecules) live in `components/`; tool-specific molecules and compounds live in the tool's view directory; the orchestrator file is the template
- **Write code that's easy to delete**: Structure code so that removing a feature, module, or block is a clean operation, not a surgical one. Self-contained units with explicit boundaries minimize merge conflicts. When conflicts do occur, the resolution should be obvious from the structure alone, no guesswork about which side to keep or how interleaved changes fit together
- **Weight reversibility**: When proposing a design choice, name whether the decision is reversible (rename, refactor, undo) or irreversible (data migration, public API, infra commitment). Bias toward reversible options when alternatives are roughly comparable. Spend the irreversibility budget consciously.

## Debugging Methodology
Debugging is hypothesis-driven, not stab-in-the-dark. Treat each bug as a scientific investigation: form a hypothesis, design a test, run it, observe, update the model. Repeat until the model matches reality.

- **Symptoms are not causes**: The first thing that fails is rarely the actual bug. A null pointer crash is a symptom; the cause is whatever invariant got violated three layers up. Trace to root.
- **Instrument before changing**: Don't apply a fix until you've directly observed the broken state. Logs, prints, breakpoints, debugger inspection. If you can't see the bug happening, you can't be sure your fix addresses it.
- **State hypotheses explicitly**: "I think X because Y, so if I change Z I expect W." Predicting the result forces calibration. A surprising result means the model is wrong, and that is a finding, not a setback.
- **Stuck more than 30 minutes? Escalate**: Rubber-duck explicitly, delegate to a debugging-focused worker, or invoke Cross-Model Consultation. Repeating what you've already tried has low yield.

## Code Style
- **Avoid cryptic abbreviations**: Use full words (`message` not `msg`, `result` not `res`, `response` not `resp`). Standard ecosystem abbreviations are acceptable when readers expect them (`id`, `url`, `ctx`, `err`, `i`, `x`, `y`, `fn`, `args`, `params`, `config`). Do not abbreviate domain concepts, project-specific names, or one-off locals. When in doubt, prefer the full word. **Reason:** the goal is readability, not a closed whitelist. Community idioms aid readability; ad-hoc abbreviations harm it.
- **Literate programming**: For longer files, scripts, tests, and files with distinct sections, write code in blocks, each with a short header comment describing the block's purpose, like a topic sentence for a paragraph. Small functions and single-purpose components don't need block headers. Group includes by category with headers (e.g. `// System Headers`, `// Standard Headers`). Block headers use Title Case (see Appendix § Title Case). The same rule applies to test-file section headers, doc-comment section dividers, and any heading-like comment that serves as structural navigation. Inline comments stay sentence case. Block headers are structural navigation ("what this section does") and serve a different purpose from inline comments
- **Method chaining**: In C++, prefer returning `T&` (or the object itself) from methods to allow fluent call chains. In Python, prefer returning `self` or new values over returning `None`
- **Comments**: Inline comments explain *why* and *intent*, not *what*. The code already says what it does. Specific rules:
  - **Express intent as "X should do Y."** Assertions of expected behavior, not descriptions of mechanism. E.g. `// process_payment should validate the input, charge the customer, and emit a receipt event`, not `// processes payments`. The "should" framing makes the comment a verifiable contract; if the code drifts, the comment becomes the bug indicator.
  - **Block headers are the exception**: They describe *what* a section does for navigation. See literate programming above. Use plain comments (`// Title` in languages with line comments, `/* Title */` in CSS). No decorative characters (box-drawing, dashes, borders).
  - **Brevity**: Comments don't need to be full sentences.
  - **Don't describe visible control flow**: No "fall through to X below."
  - **No duplication**: Don't repeat what a nearby comment or docstring says.
- **Control flow**: Use guard clauses and early returns to keep the main logic at the top indentation level. Prefer positive/true-by-default checks over if-not patterns; structure conditionals so the happy path reads as the default case
- **Conciseness**: Keep `raise`/`throw` statements on a single line when the message fits. Inline single-use variables when the expression is clear enough on its own. Prefer async/await over callback chains (`.then()` in JS, raw coroutine wiring in Python) in any language that supports it
- **DOM minimalism** (web frontends): Every DOM element must justify its existence. Prefer CSS solutions (pseudo-elements, grid, adjacent-sibling selectors) over wrapper elements for decorative or layout-only concerns. Audit wrapper divs before shipping: if it's not a positioning context, flex/grid container, semantic grouping, or conditional layout boundary, remove it. Use data-driven rendering (.map over config) instead of repeated near-identical markup

## Anti-Patterns

- **Don't add tests for typos or cosmetic changes**: tier-mismatched effort.
- **Don't refactor adjacent code while fixing a bug**: scope creep masks the fix and complicates rollback.
- **Don't introduce abstractions on the first pass**: wait for the second use. Three similar lines beat premature abstraction. Exception: when the abstraction immediately improves clarity or prevents likely misuse.
- **Don't suppress warnings or linter errors without justification**: warnings often flag real bugs.

## Appendix

- **File and function smell thresholds**: ~40 lines per function, ~200 lines per file as smell signals, not hard limits. The real signal is whether the unit has a single coherent responsibility. A 300-line file of related type definitions is fine. A 150-line file mixing request handling and business logic needs splitting.
- **Font weights** (web/UI): 400, 600, 700 only. 500 is banned (Segoe UI on Windows lacks it).

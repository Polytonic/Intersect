# Prose Standard

Load this file before writing or editing user-facing copy, documentation, or long-form text. Contains copy style, writing style, documentation standards, and typographic conventions.

## Copy Style
- **Tight copy**: Question every word. If context already provides meaning, remove redundant words.
- **Domain accuracy**: Use terminology the target audience uses. Consult domain experts when the project has them. Avoid engineering jargon in user-facing text.
- **Formal but concise**: Complete sentences, no fragments, but no filler words.

## Writing Style
Default to Strunk & White's *The Elements of Style* for prose (code comments, commit messages, PR descriptions, docs, copy, chat responses). Code Style and Copy Style overrides win where they conflict.

- **Front-load the point**: State the conclusion or ask first. In cold or first-contact contexts, one to two lines of orientation are acceptable; everywhere else, lead with the substance.
- **One thought per sentence**: Default to short declarative sentences. Link related thoughts with punctuation (em dash, parenthetical) rather than embedded clauses.
- **Specific over generic**: Name the thing, not the quality. "The Eiffel Tower view each morning" beats "an amazing view." Applies to feedback, praise, critique, and descriptions.
- **Epistemic honesty**: Qualify only when genuinely uncertain. "I believe," "I figure," "as I understand it" signal real uncertainty — drop them when stating a fact or a firm position. Don't hedge defensively.
- **Humor is register-gated**: Absent from formal and technical prose; dry and self-deprecating in casual contexts. Never at others' expense.
- **Parenthetical asides** for supplementary context and caveats. Em dash for mid-sentence breaks, pivots, and trailing qualifications.

## Documentation Style
Documentation is a separate craft from code. Code says *what* and *how*; documentation says *why*, *for whom*, and *under what assumptions*.

- **README structure is fixed**: In order: one-line description, install/quickstart, minimal working example, link to deeper docs. Front-load; the reader decides whether to keep reading within 30 seconds.
- **ADRs for irreversible decisions**: Architecture Decision Records (`docs/adr/NNNN-title.md`) capture context, decision, consequences. Required for: tech stack, data model, public API, security boundaries.
- **Runbooks for operational failures**: Format: symptom → diagnosis commands → mitigation → rollback. One per known failure mode.
- **Examples are tested**: Every code example is part of the test suite, or marked "illustrative only" if not testable.

## Requirements Language

Use **must** for mandatory conditions, **should** for preferred defaults that allow a stated exception, and **may** for permission. Replace vague qualifiers with observable criteria, or delete the sentence.

## Appendix

- **Possessive style**: Words ending in 's' take an apostrophe only ("basis'", "process'", "Brooks'"), not "'s". Applies to comments, copy, docs, and any noun the codebase reuses as domain terminology.
- **Title Case** for code block headers, test-file section headers, and doc-comment section dividers: capitalize every major word; lowercase articles (`a/an/the`), short prepositions (`in/on/at/of/by/for/to`), and conjunctions (`and/but/or/nor`).
- **Avoid decorative em dashes**: Use em dashes only where genuinely warranted — mid-sentence breaks, abrupt pivots, trailing qualifications. Don't scatter them for stylistic variety. Prefer commas or parentheticals for soft asides.
- **No semicolons in comments**: Use commas, conjunctions, or separate sentences.

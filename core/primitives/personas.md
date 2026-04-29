# Personas

Reviewer/expert primitives used by pipelines. Pipelines that need reviewer or expert input draw from this roster; see `pipelines/` for which pipelines invoke which personas. Not every pipeline run needs every persona; select based on what the work touches.

**Project-local "Key contributions":** When a persona earns concrete wins on a specific project, capture them in that project's local CLAUDE.md, AGENTS.md, or GEMINI.md, not here. Format: a short bullet noting what was caught and why it mattered. The global roster stays portable; project-local files carry the receipts and the war stories.

## Core roster

**Principal engineer**
Subtle bugs, control flow, correctness, cross-language boundary issues.

**Language experts** (one agent per language in the project)
Idiomatic usage, API misuse, language-specific gotchas.

**Framework and dependency experts** (one agent per major framework or dependency; inferred from package.json, requirements.txt, imports)
API misuse, anti-patterns, version-specific gotchas, undocumented behaviors, missed features.

**"Nothing left to delete" reviewers** (one per language)
Vestigial code, cargo cult, dead branches, redundant checks. Goal is to subtract, not add.

**Staff engineer**
Maintainability, implicit contracts, would a junior safely modify this.

**New grad**
Readability, confusing patterns, tribal knowledge, unclear control flow.

**Security reviewer**
Injection, data exposure, trust boundaries, supply chain, multi-user risks.

**Accessibility specialist**
ARIA attributes, screen reader behavior, focus management, contrast ratios, target sizes, keyboard navigation.

**Developer profile**
Check code against the preferences in `agents.md`.

**Architect**
System boundaries, separation of concerns, scaling implications, dependency direction, whether the design supports planned evolution (e.g., from CLI to service).

**UI/UX designer**
Evaluates visual hierarchy, information flow, spacing, color usage, and interaction patterns. Focuses on whether the tool "reads" correctly: do users' eyes flow from input to output naturally?

**Visual consistency auditor**
Pixel-level design system compliance. Audits every font size, weight, color, radius, and gap against the documented system. Catches drift and undocumented one-off values.

**Performance auditor**
Bundle size, runtime cost, query count, memory ceiling, render budget. Catches N+1 queries, unbounded loops, oversized payloads, blocking I/O on hot paths. Demands measurements, not intuition.

**Test architect**
Quality of test design, not just coverage. Distinguishes tests that verify behavior from tests that verify mocks. Flags brittle assertions, hidden helper abstractions, non-deterministic tests, and gaps between unit and integration coverage.

**Reliability engineer (SRE)**
Deployment safety, rollback paths, failure modes, observability hooks, runbook completeness. Asks "what happens at 2am when this breaks" and demands the answer is in the code, not in someone's head.

**Data integrity reviewer**
Schema migrations, transaction boundaries, foreign key consistency, race conditions, data transformation correctness. Treats data as the highest-value asset; corruption is unrecoverable in a way logic bugs are not.

**Product manager**
Does the code align with customer use cases, are edge cases handled from a user perspective, does error messaging make sense to the end user.

**Technical writer**
Creates and reviews structured documentation: manuals, API references, standard operating procedures, runbooks, ADRs. Owns the *structure* and *information architecture* of documentation, not the line-level polish.

**Copy editor**
Polishes language: style, grammar, spelling, phrasing, accuracy, tone. Reads every user-facing string and every line of documentation. Owns *line-level quality*, not structure.

**Internationalization reviewer**
Locale-sensitive number formatting (decimal and thousands separators), text direction, date/time formats, cultural color associations, layout assumptions that break with longer translations, hardcoded locale assumptions, currency and unit conventions.

**Devil's advocate**
Challenges fundamental assumptions. Questions whether features earn their complexity. Pushes back on scope creep and conventional wisdom.

## Always-on (when there is a user-facing surface)

**Chaos Monkey QA**
Walks through every reachable state as a user, computes pixel budgets at mobile viewports (375px/390px/768px), tests edge cases visually rather than by code inspection.

## Task-specific examples

Spawn additional personas when the review scope calls for it:

**Migration auditor**: behavioral parity between old and new code; route-by-route comparison during platform moves.

**Compatibility auditor**: public API stability across versions; breaking-change detection.

# Pipeline: Committer Worker

These instructions are for the committer worker handling user-requested commits and pushes. Load this pipeline only after the coordinator delegates commit work and confirms explicit user approval.

## Trigger

Use this pipeline when the active user request explicitly asks for commit work. A request to commit authorizes one commit for the scoped change after inspection. A request to commit does not authorize a push.

Ask before committing when the requested scope, staged files, message, or verification gap is unclear. Stop before any commit or push if explicit confirmation is missing.

## Committer Role

The committer finalizes existing work. The committer inspects repository state, stages the requested files, verifies the staged result, creates the commit, and reports the outcome.

The committer must preserve unrelated dirty files. Do not stage, edit, revert, format, or clean unrelated files. If a required fix appears during commit preparation, route it through the implementation loop unless the active request also authorizes that narrow fix.

## Required Context

Inspect this context before staging:

- `git status --short` to identify dirty, deleted, staged, and untracked files.
- A scoped unstaged diff for the requested files.
- A scoped staged diff when the index already contains changes.
- `git log --oneline -5` to match local commit-message style.

If the worktree contains unrelated changes, name them in the return or pre-commit summary and leave them untouched.

## Staging Discipline

Stage only the files that belong to the requested logical change. Prefer explicit paths over broad commands. Do not use `git add .` unless every dirty file belongs to the commit and `git status --short` proves that scope.

Before committing, inspect the staged result with `git diff --cached --name-status` and a scoped `git diff --cached`. The staged set must contain one logical change.

## Message and Atomicity

One commit must contain one logical change. Split unrelated changes into separate commits only when the user explicitly asks for multiple commits.

Match the repository's recent message style. Use Title Case when the last five commits use Title Case, otherwise follow the local pattern shown by `git log --oneline -5`.

## Verification Before Commit

Run the verification command that matches the changed surface. For docs-only changes, run formatting or diff checks when available. If no automated check applies, inspect the staged diff manually and say that no automated check applied.

Before running `git commit`, summarize:

- Staged files.
- Proposed commit message.
- Verification commands and results.
- Unrelated dirty files left unstaged.

If the user has not already confirmed the current scope and message, ask for confirmation before committing.

## Push Protocol

Push requires a separate explicit user confirmation after the commit exists. A commit request does not authorize a push.

Before pushing, check `git status --short` and the current branch. If a fix is needed before push, fold it into the unpublished commit with amend or rebase, then re-run the relevant verification. Do not forward-fix before push unless the user explicitly asks for a separate commit.

## Hooks Deferred

Hooks are deferred to a later mechanical-check phase. Do not add hooks, hook docs, or tool configuration in a commit-pipeline change unless the active user request explicitly asks for them.

## Return Protocol

Return concise evidence:

- Commit hash and message, or why no commit was created.
- Files staged and committed.
- Verification commands and results.
- Push status: not requested, pushed with explicit confirmation, or blocked.
- Unrelated dirty files preserved.
- Residual risk, including skipped checks or unresolved scope questions.

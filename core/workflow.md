# Shared Workflow
This contract applies to coordinator, workers, and verifiers. The coordinator entry or delegated brief determines the role. A general worker owns the requested outcome, including relevant checks and documentation; applicable domain cards supply mandatory standards.

## Terminal Consultation
Handle terminal dispatch before other routing. Every consultant brief must contain the exact line `Terminal consultation: yes`, plus persona, question or scope, relevant context, and expected return. Missing marker: fail before launch.

That marker overrides coordinator routing, profile loading, worker brief fields, downstream chains, and consultation requirements. The consultant directly assesses the named question, never routes, delegates, consults, spawns, or creates descendants, and returns to its owning worker. The owner retains synthesis and any sibling consultations. Scope, authorization, confidentiality, and read-only restrictions still apply.

## Authority And Preservation
- The active request defines scope, downstream chain, and permissions. Carry existing grants through briefs without blanket reauthorization; they do not waive applicable safeguards.
- Ask before MCP, app, plugin, network, dependencies, new files, or other external-service use unless already authorized. Never disclose secrets or private data externally without explicit scoped authorization; never expose credentials.
- Identify irreversible choices and ask before taking one when a reversible path also works. Stop on unresolved scope or authority conflicts; complete unaffected authorized work when possible.
- Inspect status and relevant staged/unstaged diffs before mutation. Preserve unrelated files and hunks, including within edited files, and existing staged work. For a dirty-file rewrite, capture a recoverable current-working-tree baseline and compare the incremental change against it. Never reset, clean, revert, format, or stage unrelated work.
- Commit, amend, and push follow the Commit card's explicit scope and confirmation gates.

## Profile Loading
`profile:` paths resolve from the loaded coordinator profile root: the parent of its `core/` directory, not the task workspace. Unprefixed paths resolve in the workspace. Every brief supplies that root and exact absolute paths for this workflow and all selected cards.

Before role work, read those exact files. Links or a claimed load are insufficient. Missing root, unreadable required file, or a resolved/loaded path mismatch is a profile-load blocker; stop and ask, without substituting a workspace decoy. Acknowledge the load once: `Loaded profiles: <absolute paths>; observed headers: <copied H1s>`. Do not repeat a full manifest in every return.

## Brief
Use four fields:
1. **Outcome** — requested result and worker or verifier role.
2. **Context** — relevant inputs, prior output, profile root, and exact workflow/card paths.
3. **Constraints And Permissions** — scope, existing changes, granted and withheld actions, selected downstream chain.
4. **Acceptance Checks** — concrete pass conditions, required verification, and evidence.

Prefer reasoning and relevant examples to procedural detail. Every downstream worker receives and addresses the previous output. Consultants use the terminal brief above.

## Delegation And Verification
- Use fresh agents or sessions with complete briefs; request no inherited conversation turns where supported. Transfer transcript context only when restating it would be lossy. Advisory workers, independent verifiers, and consultants stay fresh. A reused author never counts as its own independent verifier or separate consultant.
- If required delegation needs permission, ask for session-scoped permission. If unavailable, report a launch/capacity blocker; the coordinator does not take over role work.
- Every worker verifies its own outcome with relevant checks. Read-only advice and mechanical changes may finish after self-checks. Require a fresh verifier for consequential changes: ordinary behavior-affecting code, multi-file policy or contracts, security, data, migrations, public interfaces, or external/irreversible effects.
- Seek a separate terminal specialist for a concrete expertise gap, conflicting evidence, or unresolved uncertainty. Name the question and how the finding affects the work; no universal persona quotas or fixed review fan-out. Uncertainty about impact requires verification rather than a low-risk assumption.
- Security-critical or irreversible work requires independent review by a different model family. Different model names alone do not establish different families. If unavailable, report a blocker.
- Verifiers inspect evidence and affected behavior against scope, user needs, applicable standards, and acceptance checks. They return repairs to the author rather than changing the work under review. Recheck affected gates after corrections; do not repeat passing checks without a reason.
- Track launched sessions to final status. Close them after verification or handoff unless immediately reused for an allowed task; if closing is unsupported, name that limitation and any capacity blocker. Do not repeatedly retry a full runtime.
- If the same failure dimension fails twice, escalate to the user with evidence and the decision needed.

## Return
Return three sections:
- **Result** — changed/found outcome and affected paths.
- **Evidence** — commands, inspected sources, exact results, and skipped checks with reasons. Include any consultant's persona, distinct session ID, model/effort and context mode if known, findings, and how they were applied. Never invent consultation or completion evidence.
- **Questions And Risks** — None, or blockers and residual uncertainty with evidence, owner, next action, and why the risk is acceptable or blocks completion.

Check every claimed requirement against evidence. Distinguish policy/scenario inspection from observed live behavior: Markdown, synthetic marker checks, and a depth backstop do not mechanically prove fresh context, actual delegation, or terminality. Keep the configured depth backstop.

#!/usr/bin/env bash
# Sandboxed test of the intersect CLI. Uses a temporary HOME so the real
# ~/.claude, ~/.codex, and ~/.gemini are never touched. Exits non-zero
# on any failure; safe to run from CI or pre-commit.

set -euo pipefail

# === Setup ===

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
INTERSECT="$REPO_DIR/bin/intersect"
TEST_HOME="$(mktemp -d)"
trap 'rm -rf "$TEST_HOME"' EXIT

EXPECTED_PROFILE_ROUTES=(
  "profile:core/subagents/research.md"
  "profile:core/subagents/design.md"
  "profile:core/subagents/coding.md"
  "profile:core/subagents/testing.md"
  "profile:core/subagents/writing.md"
  "profile:core/subagents/reviewing.md"
  "profile:core/subagents/commit.md"
)

EXPECTED_LINK_MAP=(
  ".claude/CLAUDE.md|core/claude.md"
  ".claude/settings.json|tools/claude/settings.json"
  ".codex/AGENTS.md|core/agents.md"
  ".codex/config.toml|tools/codex/config.toml"
  ".gemini/GEMINI.md|core/agents.md"
  ".gemini/settings.json|tools/gemini/settings.json"
)

COORDINATOR_EVIDENCE_MARKERS=(
  "When requirements are unclear or instructions conflict in a way that could change the outcome, stop and ask before routing or acting."
  "Active user requests set task scope, downstream chain, and permissions. They do not skip required process steps: delegation, profile loading, consultation, verification, dirty-file preservation, ambiguous commit-scope clarification, amend confirmation, or separate push confirmation."
  "Commit and push requests route through the Commit profile."
  "Outputs must require the five return sections plus evidence for delegation, verification, consultation, blockers, and residual risk."
  "Every delegated brief must require a delegation manifest in \`Changed/found\`: profile route, resolved path, profile H1, model/effort if known, isolation/context mode and agent id if known, external-service permission state."
  "**Delegation manifest**: \`Changed/found\` names the profile route, resolved path, profile H1, isolation/context mode, agent id if known, model/effort if known, and external-service permission state."
  "**Verification evidence**: \`Verified\` names commands, inspected sources, exact results, and skipped gates with reasons."
  "Reject claim-only verification."
  "**Consultation evidence**: \`Consulted\` names each required consultant's persona, delegated agent id or separate-session identifier, model/effort if known, isolation/context mode, prompt scope, findings, and changes made in response, or why none were made."
  "If the runtime cannot launch a separate consultant, \`Consulted\` names the blocked reason."
  "For each required persona, launch a separate consultant agent or session; do not write the consultant answer yourself."
  "Each consultant brief names the persona, question or scope, relevant files or context, and expected return."
  "**Blocker evidence**: \`Questions/blockers\` states \`None\` or lists each blocker with evidence, owner, and next action."
  "**Residual-risk evidence**: \`Residual risk\` states \`None\` or names remaining uncertainty, evidence, and why it is acceptable or blocked."
  "**Domain gates**: Verify the subagent addressed the brief's Done-when criteria and downstream outputs. Do not invent domain-specific acceptance criteria after dispatch."
  "**All work**: Subagent verified own work. Each downstream subagent received and addressed previous subagent's output."
  "launch a separate consultant agent or session"
  "do not write the consultant answer yourself"
  "If the runtime cannot launch one, return a blocker."
  "Same dimension fails twice → escalate to the user."
)

SUBAGENT_RETURN_PROTOCOL_MARKERS=(
  "Return sections exactly: **Changed/found**, **Verified**, **Consulted**, **Questions/blockers**, **Residual risk**."
  "**Changed/found** begins with the delegation manifest: profile route, resolved path, profile H1"
  "external-service permission state"
  "If the profile cannot be loaded"
  "**Verified**"
  "exact results"
  "skipped gates with reasons"
  "**Consulted** includes each required consultant's persona, delegated agent id or separate-session identifier"
  "prompt scope, findings, and changes made in response, or why none were made"
  "Each consultant brief names the persona, question or scope, relevant files or context, and expected return."
  "If the runtime cannot launch a separate consultant, include the blocked reason."
  "**Questions/blockers** states \`None\` or lists"
  "evidence, owner, and next action"
  "**Residual risk**"
  "evidence, and why"
  "acceptable or blocked"
)

SUBAGENT_CONSULTATION_MARKERS=(
  "separate consultant agent or session"
  "Do not write the consultant answer yourself"
  "If the runtime cannot launch one, return a blocker."
)

PROFILE_CLEANUP_FORBIDDEN_MARKERS=(
  "Conflict ord""er"
  "conflict lad""der"
  "self""-scan"
  "routine impl""ementation"
  "risk s""can"
)

CODING_PROFILE_ASK_FIRST_MARKERS=(
  "**Missing rule = ask**: If the spec and standards do not determine the implementation, return a question or blocker instead of inventing a preference."
  "**Named-pattern gate**: Follow these standards unless the brief explicitly names a conflicting local pattern."
  "If following these standards would break the existing system and the brief does not name the pattern, stop and return a blocker."
)

CODING_PROFILE_CONSULTATION_MARKERS=(
  "select the first roster item whose description names the changed surface"
  "select Staff engineer when no item matches"
  "Launch that persona as a separate consultant agent or session."
)

REVIEW_PROFILE_MARKERS=(
  "1. **User lens**: User's goals, constraints, preferences. Mandatory for every review, advisory task, and workflow decision."
  "2. **Coordinator profile**: Check output against \`core/agents.md\`."
  "Minimum selection: Always-On consultants plus every persona in each touched category."
)

COMMIT_PROFILE_MARKERS=(
  "launch a separate consultant agent or session"
  "Do not write the consultant answer yourself"
  "If the runtime cannot launch one, return a blocker."
  "Copy editor"
  "Commit title lines must use Title Case."
  "Copy-editor consultation must flag non-Title-Case titles before finalizing."
  "Commit messages must include a short body explaining what changed and why."
  "Title-only messages need explicit user direction."
  "Push requires separate explicit confirmation."
  "## State Machine"
  "**Preflight Status**"
  "**Freeze Scope**"
  "**Stage Explicit Paths**"
  "**Cache Diff**"
  "**Verify Surface**"
  "**Draft Message**"
  "**Consult Message**"
  "**Pre-Commit Summary**"
  "**Commit Or Amend**"
  "**Post-Commit Status**"
  "**Push Gate**"
)

if [[ -t 1 ]]; then
  C_PASS=$'\033[0;32m'
  C_FAIL=$'\033[0;31m'
  C_RESET=$'\033[0m'
else
  C_PASS=""; C_FAIL=""; C_RESET=""
fi

PASSED=0
FAILED=0

pass() { echo "${C_PASS}✓${C_RESET} $1"; PASSED=$((PASSED + 1)); }
fail() { echo "${C_FAIL}✗${C_RESET} $1"; echo "    $2"; FAILED=$((FAILED + 1)); }

file_missing_markers() {
  local file="$1" label="$2"
  shift 2
  local marker missing=""

  for marker in "$@"; do
    if ! grep -Fq -- "$marker" "$file"; then
      if [[ -n "$missing" ]]; then
        missing="$missing; "
      fi
      missing="$missing$label missing: $marker"
    fi
  done

  printf '%s' "$missing"
}

file_containing_markers() {
  local file="$1" label="$2"
  shift 2
  local marker found=""

  for marker in "$@"; do
    if grep -Fq -- "$marker" "$file"; then
      if [[ -n "$found" ]]; then
        found="$found; "
      fi
      found="$found$label contains stale marker: $marker"
    fi
  done

  printf '%s' "$found"
}

# fresh_home should reset $TEST_HOME between tests so state from one
# test never leaks into the next. Keeps tests independent.
fresh_home() {
  rm -rf "$TEST_HOME"
  mkdir -p "$TEST_HOME"
}

# assert_symlink should pass when $dest is a symlink whose target equals
# $expected, and fail with a diff-style message otherwise.
assert_symlink() {
  local dest="$1" expected="$2" msg="$3"
  local actual
  actual="$(readlink "$dest")"
  if [[ "$actual" == "$expected" ]]; then
    pass "$msg"
  else
    fail "$msg" "expected $expected, got $actual"
  fi
}

# === Tests ===

test_link_creates_expected_symlinks() {
  fresh_home
  HOME="$TEST_HOME" "$INTERSECT" link >/dev/null
  assert_symlink "$TEST_HOME/.claude/CLAUDE.md" "$REPO_DIR/core/claude.md" \
    "link creates ~/.claude/CLAUDE.md → core/claude.md"
}

test_link_creates_settings_symlinks() {
  fresh_home
  HOME="$TEST_HOME" "$INTERSECT" link >/dev/null
  assert_symlink "$TEST_HOME/.codex/config.toml" "$REPO_DIR/tools/codex/config.toml" \
    "link creates ~/.codex/config.toml → tools/codex/config.toml"
}

test_link_creates_declared_symlink_map() {
  fresh_home
  HOME="$TEST_HOME" "$INTERSECT" link >/dev/null
  local spec dest_rel source_rel actual missing=""

  for spec in "${EXPECTED_LINK_MAP[@]}"; do
    dest_rel="${spec%%|*}"
    source_rel="${spec##*|}"
    if [[ ! -L "$TEST_HOME/$dest_rel" ]]; then
      missing="$missing missing:~/$dest_rel"
      continue
    fi
    actual="$(readlink "$TEST_HOME/$dest_rel")"
    if [[ "$actual" != "$REPO_DIR/$source_rel" ]]; then
      missing="$missing wrong:~/$dest_rel→$actual"
    fi
  done

  if [[ -z "$missing" ]]; then
    pass "link creates declared symlink map"
  else
    fail "declared symlink map" "$missing"
  fi
}

test_profile_routes_point_to_existing_files() {
  local route rel missing=""

  for route in "${EXPECTED_PROFILE_ROUTES[@]}"; do
    rel="${route#profile:}"
    if [[ ! -f "$REPO_DIR/$rel" ]]; then
      missing="$missing missing:$rel"
      continue
    fi
    if ! grep -Fq "\`$route\`" "$REPO_DIR/core/agents.md"; then
      missing="$missing unreferenced:$route"
    fi
  done

  if [[ -z "$missing" ]]; then
    pass "profile subagent routes point to existing files"
  else
    fail "profile subagent routes" "$missing"
  fi
}

test_coordinator_profile_evidence_gates() {
  local missing
  missing="$(file_missing_markers \
    "$REPO_DIR/core/agents.md" \
    "core/agents.md" \
    "${COORDINATOR_EVIDENCE_MARKERS[@]}")"

  if [[ -z "$missing" ]]; then
    pass "coordinator profile requires evidence-backed gates"
  else
    fail "coordinator profile evidence gates" "$missing"
  fi
}

test_subagent_profiles_require_evidence_returns() {
  local file short file_missing missing=""

  for file in "$REPO_DIR"/core/subagents/*.md; do
    short="${file#$REPO_DIR/}"
    file_missing="$(file_missing_markers \
      "$file" \
      "$short" \
      "${SUBAGENT_RETURN_PROTOCOL_MARKERS[@]}" \
      "${SUBAGENT_CONSULTATION_MARKERS[@]}")"
    if [[ -n "$file_missing" ]]; then
      if [[ -n "$missing" ]]; then
        missing="$missing; "
      fi
      missing="$missing$file_missing"
    fi
  done

  if [[ -z "$missing" ]]; then
    pass "subagent profiles require manifest, separate consultant launch, verification, blocker, and residual-risk evidence"
  else
    fail "subagent return evidence contracts" "$missing"
  fi
}

test_profiles_omit_stale_conflict_and_consultation_exceptions() {
  local file short found missing=""

  found="$(file_containing_markers \
    "$REPO_DIR/core/agents.md" \
    "core/agents.md" \
    "${PROFILE_CLEANUP_FORBIDDEN_MARKERS[@]}")"
  missing="$found"

  for file in "$REPO_DIR"/core/subagents/*.md; do
    short="${file#$REPO_DIR/}"
    found="$(file_containing_markers \
      "$file" \
      "$short" \
      "${PROFILE_CLEANUP_FORBIDDEN_MARKERS[@]}")"
    if [[ -n "$found" ]]; then
      if [[ -n "$missing" ]]; then
        missing="$missing; "
      fi
      missing="$missing$found"
    fi
  done

  if [[ -z "$missing" ]]; then
    pass "profiles omit stale conflict and consultation exceptions"
  else
    fail "stale profile cleanup markers" "$missing"
  fi
}

test_coding_profile_preserves_ask_first_gates() {
  local missing
  missing="$(file_missing_markers \
    "$REPO_DIR/core/subagents/coding.md" \
    "core/subagents/coding.md" \
    "${CODING_PROFILE_ASK_FIRST_MARKERS[@]}" \
    "${CODING_PROFILE_CONSULTATION_MARKERS[@]}")"

  if [[ -z "$missing" ]]; then
    pass "coding profile preserves ask-first and consultant-launch gates"
  else
    fail "coding profile ask-first and consultant-launch gates" "$missing"
  fi
}

test_review_profile_preserves_user_lens() {
  local missing
  missing="$(file_missing_markers \
    "$REPO_DIR/core/subagents/reviewing.md" \
    "core/subagents/reviewing.md" \
    "${REVIEW_PROFILE_MARKERS[@]}")"

  if [[ -z "$missing" ]]; then
    pass "review profile preserves User lens and coordinator gate"
  else
    fail "review profile User lens gate" "$missing"
  fi
}

test_commit_profile_state_machine_and_message_rules() {
  local missing
  missing="$(file_missing_markers \
    "$REPO_DIR/core/subagents/commit.md" \
    "core/subagents/commit.md" \
    "${COMMIT_PROFILE_MARKERS[@]}")"

  if [[ -z "$missing" ]]; then
    pass "commit profile preserves state machine and message gates"
  else
    fail "commit profile state machine and message rules" "$missing"
  fi
}

test_link_is_idempotent() {
  fresh_home
  HOME="$TEST_HOME" "$INTERSECT" link >/dev/null
  local output
  output="$(HOME="$TEST_HOME" "$INTERSECT" link)"
  if echo "$output" | grep -q "0 new"; then
    pass "link is idempotent (0 new on re-run)"
  else
    fail "link idempotency" "expected '0 new' in output, got: $output"
  fi
}

test_link_per_tool_filtering() {
  fresh_home
  HOME="$TEST_HOME" "$INTERSECT" link claude >/dev/null
  if [[ -L "$TEST_HOME/.claude/CLAUDE.md" ]] \
     && [[ ! -e "$TEST_HOME/.codex/AGENTS.md" ]] \
     && [[ ! -e "$TEST_HOME/.gemini/GEMINI.md" ]]; then
    pass "link claude only touches ~/.claude"
  else
    fail "link claude" "claude alone should not have created codex/gemini links"
  fi
}

test_unlink_refuses_to_remove_real_files() {
  fresh_home
  HOME="$TEST_HOME" "$INTERSECT" link >/dev/null
  rm "$TEST_HOME/.claude/CLAUDE.md"
  echo "real user content" > "$TEST_HOME/.claude/CLAUDE.md"
  local output
  output="$(HOME="$TEST_HOME" "$INTERSECT" unlink claude 2>&1)"
  if [[ -f "$TEST_HOME/.claude/CLAUDE.md" ]] && echo "$output" | grep -q "skipped"; then
    pass "unlink refuses to remove non-symlink files"
  else
    fail "unlink safety" "real file may have been removed; output: $output"
  fi
}

test_unlink_removes_only_our_symlinks() {
  fresh_home
  HOME="$TEST_HOME" "$INTERSECT" link >/dev/null
  HOME="$TEST_HOME" "$INTERSECT" unlink >/dev/null
  if [[ ! -e "$TEST_HOME/.claude/CLAUDE.md" ]] && [[ ! -e "$TEST_HOME/.codex/AGENTS.md" ]]; then
    pass "unlink removes our symlinks"
  else
    fail "unlink removal" "symlinks were not removed"
  fi
}

test_install_through_symlink_resolves_repo_dir() {
  # When invoked through a PATH symlink, intersect should resolve REPO_DIR by
  # following the symlink to the real repo, not by using the symlink's parent.
  fresh_home
  HOME="$TEST_HOME" "$INTERSECT" install "$TEST_HOME/bin" >/dev/null
  HOME="$TEST_HOME" "$INTERSECT" link >/dev/null
  local doctor_output
  doctor_output="$(HOME="$TEST_HOME" "$TEST_HOME/bin/intersect" doctor 2>&1)"
  if echo "$doctor_output" | grep -q "All systems go"; then
    pass "doctor via PATH symlink resolves REPO_DIR correctly"
  else
    fail "doctor via symlink" "doctor reported issues when invoked through symlinked CLI"
  fi
}

test_system_bash_doctor_runs_after_repo_file_enumeration() {
  fresh_home
  HOME="$TEST_HOME" "$INTERSECT" link >/dev/null
  local output
  output="$(HOME="$TEST_HOME" /bin/bash "$INTERSECT" doctor 2>&1 || true)"
  if echo "$output" | grep -q "All systems go"; then
    pass "system bash doctor runs past repo-file enumeration"
  else
    fail "system bash doctor" "expected clean doctor output, got: $output"
  fi
}

test_install_is_idempotent() {
  fresh_home
  HOME="$TEST_HOME" "$INTERSECT" install "$TEST_HOME/bin" >/dev/null
  local output
  output="$(HOME="$TEST_HOME" "$INTERSECT" install "$TEST_HOME/bin")"
  if echo "$output" | grep -q "already installed"; then
    pass "install is idempotent"
  else
    fail "install idempotency" "expected 'already installed', got: $output"
  fi
}

test_uninstall_refuses_to_remove_foreign_symlinks() {
  fresh_home
  mkdir -p "$TEST_HOME/bin"
  ln -s /usr/bin/true "$TEST_HOME/bin/intersect"
  # Capture into a variable so pipefail doesn't trip on intersect's exit 1.
  local output
  output="$(HOME="$TEST_HOME" "$INTERSECT" uninstall "$TEST_HOME/bin" 2>&1 || true)"
  if echo "$output" | grep -q "refusing"; then
    pass "uninstall refuses to remove foreign symlinks"
  else
    fail "uninstall safety" "should have refused; output: $output"
  fi
}

test_update_errors_when_repo_is_not_git() {
  # update should fail with a clear message when REPO_DIR has no .git/.
  fresh_home
  local fake_repo="$TEST_HOME/fake_repo"
  mkdir -p "$fake_repo/bin"
  cp "$INTERSECT" "$fake_repo/bin/intersect"
  local output
  output="$(HOME="$TEST_HOME" "$fake_repo/bin/intersect" update 2>&1 || true)"
  if echo "$output" | grep -q "not a git repository"; then
    pass "update errors when REPO_DIR is not a git repo"
  else
    fail "update error path" "expected 'not a git repository', got: $output"
  fi
}

test_update_invokes_pull_in_git_repo() {
  # update should announce the pull (by printing the Pulling message) once
  # REPO_DIR is a real git repo. The pull itself may fail on a fresh init
  # without a remote; that exits non-zero, but the announce should still
  # have happened first.
  fresh_home
  local fake_repo="$TEST_HOME/fake_repo"
  mkdir -p "$fake_repo/bin"
  cp "$INTERSECT" "$fake_repo/bin/intersect"
  git init -q "$fake_repo"
  local output
  output="$(HOME="$TEST_HOME" "$fake_repo/bin/intersect" update 2>&1 || true)"
  if echo "$output" | grep -q "Pulling"; then
    pass "update announces the pull when REPO_DIR is a git repo"
  else
    fail "update happy path" "expected 'Pulling' message, got: $output"
  fi
}

test_unknown_command_errors_cleanly() {
  local output
  output="$("$INTERSECT" frobnicate 2>&1 || true)"
  if echo "$output" | grep -q "unknown command"; then
    pass "unknown command produces clean error"
  else
    fail "unknown command" "expected error message; output: $output"
  fi
}

test_unknown_tool_errors_cleanly() {
  fresh_home
  local output
  output="$(HOME="$TEST_HOME" "$INTERSECT" link bogus 2>&1 || true)"
  if echo "$output" | grep -q "unknown tool"; then
    pass "unknown tool produces clean error"
  else
    fail "unknown tool" "expected error message; output: $output"
  fi
}

# === Run All ===

test_link_creates_expected_symlinks
test_link_creates_settings_symlinks
test_link_creates_declared_symlink_map
test_profile_routes_point_to_existing_files
test_coordinator_profile_evidence_gates
test_subagent_profiles_require_evidence_returns
test_profiles_omit_stale_conflict_and_consultation_exceptions
test_coding_profile_preserves_ask_first_gates
test_review_profile_preserves_user_lens
test_commit_profile_state_machine_and_message_rules
test_link_is_idempotent
test_link_per_tool_filtering
test_unlink_refuses_to_remove_real_files
test_unlink_removes_only_our_symlinks
test_install_through_symlink_resolves_repo_dir
test_system_bash_doctor_runs_after_repo_file_enumeration
test_install_is_idempotent
test_uninstall_refuses_to_remove_foreign_symlinks
test_update_errors_when_repo_is_not_git
test_update_invokes_pull_in_git_repo
test_unknown_command_errors_cleanly
test_unknown_tool_errors_cleanly

echo ""
echo "Passed: $PASSED, Failed: $FAILED"
exit "$FAILED"

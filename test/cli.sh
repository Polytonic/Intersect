#!/usr/bin/env bash
# Deterministic intersect CLI/profile checks. Uses a temporary HOME only.

set -euo pipefail

# === Setup ===

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
INTERSECT="$REPO_DIR/bin/intersect"
TEST_HOME="$(mktemp -d)"
trap 'rm -rf "$TEST_HOME"' EXIT

EXPECTED_LINK_MAP=(
  ".claude/CLAUDE.md|core/claude.md"
  ".claude/settings.json|tools/claude/settings.json"
  ".codex/AGENTS.md|core/agents.md"
  ".codex/config.toml|tools/codex/config.toml"
  ".gemini/GEMINI.md|core/agents.md"
  ".gemini/settings.json|tools/gemini/settings.json"
)

CODING_PROFILE_ASK_FIRST_MARKERS=(
  "**Missing rule = ask**: If the spec and standards do not determine the implementation, return a question or blocker."
  "**Named-pattern gate**: Follow these standards unless the brief names a conflicting local pattern."
  "Follow the named pattern; block if these standards would break the system and no pattern is named."
)

COMMIT_PROFILE_MARKERS=(
  "Commit title lines must use Title Case."
  "Commit messages must include a short body explaining what changed and why."
  "Omit the body only when the user explicitly requests a title-only message."
  "Push requires separate explicit confirmation."
  "current-conversation, and task-scoped"
  "ambiguous scope, unrelated files, amend, title-only message, or push"
  "Verify no credentials, tokens, or keys are staged."
  "git diff --cached"
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

is_markdown_heading_line() {
  local line="$1"

  case "$line" in
    "# "* | "## "* | "### "* | "#### "* | "##### "* | "###### "*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

markdown_heading_text() {
  local heading="$1"

  while [[ "$heading" == \#* ]]; do
    heading="${heading#\#}"
  done
  while [[ "$heading" == " "* || "$heading" == $'\t'* ]]; do
    heading="${heading#"${heading:0:1}"}"
  done

  printf '%s' "$heading"
}

is_title_case_heading_part() {
  local part="$1"
  local i char

  while [[ -n "$part" && "$part" == [![:alnum:]]* ]]; do
    part="${part:1}"
  done
  while [[ -n "$part" && "$part" == *[![:alnum:]] ]]; do
    part="${part:0:${#part}-1}"
  done
  if [[ -z "$part" ]]; then
    return 0
  fi

  for ((i = 0; i < ${#part}; i++)); do
    char="${part:i:1}"
    if [[ "$char" == [[:alpha:]] ]]; then
      [[ "$char" == [[:upper:]] ]]
      return
    fi
  done

  return 0
}

is_title_case_heading_token() {
  local token="$1"
  local part normalized
  local parts=()

  normalized="${token//\// }"
  normalized="${normalized//-/ }"
  read -r -a parts <<<"$normalized"
  for part in "${parts[@]}"; do
    if ! is_title_case_heading_part "$part"; then
      return 1
    fi
  done

  return 0
}

file_heading_case_violations() {
  local file="$1" label="$2"
  local heading line token
  local line_number=0
  local tokens=()
  local violations=""

  while IFS= read -r line || [[ -n "$line" ]]; do
    line_number=$((line_number + 1))
    if ! is_markdown_heading_line "$line"; then
      continue
    fi

    heading="$(markdown_heading_text "$line")"
    read -r -a tokens <<<"$heading"
    for token in "${tokens[@]}"; do
      if is_title_case_heading_token "$token"; then
        continue
      fi
      if [[ -n "$violations" ]]; then
        violations="$violations; "
      fi
      violations="$violations$label:$line_number non-Title-Case heading: $heading"
      break
    done
  done < "$file"

  printf '%s' "$violations"
}

shell_section_header_text() {
  local line="$1"

  case "$line" in
    "# === "*)
      line="${line#"# === "}"
      line="${line%" ==="}"
      ;;
    "# "*)
      line="${line#"# "}"
      ;;
    *)
      printf ''
      return
      ;;
  esac

  case "$line" in
    *"." | *"," | *";" | *":" | *"!" | *"?" | *"("* | *")"* | *"'"*)
      printf ''
      return
      ;;
  esac

  printf '%s' "$line"
}

file_shell_section_header_case_violations() {
  local file="$1" label="$2"
  local line heading token
  local line_number=0
  local tokens=()
  local violations=""

  while IFS= read -r line || [[ -n "$line" ]]; do
    line_number=$((line_number + 1))
    heading="$(shell_section_header_text "$line")"
    if [[ -z "$heading" ]]; then
      continue
    fi

    read -r -a tokens <<<"$heading"
    for token in "${tokens[@]}"; do
      if is_title_case_heading_token "$token"; then
        continue
      fi
      if [[ -n "$violations" ]]; then
        violations="$violations; "
      fi
      violations="$violations$label:$line_number non-Title-Case shell section header: $heading"
      break
    done
  done < "$file"

  printf '%s' "$violations"
}

# fresh_home should keep tests independent.
fresh_home() {
  rm -rf "$TEST_HOME"
  mkdir -p "$TEST_HOME"
}

# === Tests ===

test_markdown_headings_use_title_case() {
  local file short file_violations missing=""

  for file in "$REPO_DIR/core/agents.md" "$REPO_DIR/core/workflow.md" "$REPO_DIR"/core/subagents/*.md "$REPO_DIR/test/readme.md"; do
    short="${file#$REPO_DIR/}"
    file_violations="$(file_heading_case_violations "$file" "$short")"
    if [[ -n "$file_violations" ]]; then
      if [[ -n "$missing" ]]; then
        missing="$missing; "
      fi
      missing="$missing$file_violations"
    fi
  done

  for file in "$REPO_DIR/test/cli.sh" "$REPO_DIR/test/verify-ai.sh"; do
    short="${file#$REPO_DIR/}"
    file_violations="$(file_shell_section_header_case_violations "$file" "$short")"
    if [[ -n "$file_violations" ]]; then
      if [[ -n "$missing" ]]; then
        missing="$missing; "
      fi
      missing="$missing$file_violations"
    fi
  done

  if [[ -z "$missing" ]]; then
    pass "profile, docs, and shell section headers use Title Case"
  else
    fail "heading Title Case" "$missing"
  fi
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
  local tick='`' line route_tail route
  local rel file actual_h1 expected_profile routed_profile found missing=""
  local expected_profiles=() routed_profiles=()

  for file in "$REPO_DIR"/core/subagents/*.md; do
    expected_profiles+=("${file#$REPO_DIR/}")
  done

  while IFS= read -r line; do
    if [[ "$line" != *"$tick"profile:core/subagents/* ]]; then
      continue
    fi

    route_tail="${line#*"$tick"profile:}"
    route="profile:${route_tail%%"$tick"*}"
    if [[ "$route" != profile:core/subagents/*.md ]]; then
      missing="$missing unsupported:$route"
      continue
    fi

    rel="${route#profile:}"
    routed_profiles+=("$rel")
    file="$REPO_DIR/$rel"
    if [[ ! -f "$file" ]]; then
      missing="$missing missing-file:$rel"
      continue
    fi

    IFS= read -r actual_h1 < "$file" || actual_h1=""
    if [[ "$actual_h1" != "# "* ]]; then
      missing="$missing h1:$rel actual:$actual_h1"
    fi
  done < "$REPO_DIR/core/agents.md"

  for expected_profile in "${expected_profiles[@]}"; do
    found=0
    for routed_profile in "${routed_profiles[@]}"; do
      if [[ "$routed_profile" == "$expected_profile" ]]; then
        found=1
        break
      fi
    done
    if [[ "$found" -eq 0 ]]; then
      missing="$missing missing-route:$expected_profile"
    fi
  done

  if [[ ! -r "$REPO_DIR/core/workflow.md" ]]; then
    missing="$missing missing-shared-workflow"
  fi
  for file in "$REPO_DIR/core/agents.md" "$REPO_DIR"/core/subagents/*.md; do
    if ! grep -Fq 'profile:core/workflow.md' "$file"; then
      missing="$missing missing-workflow-reference:${file#$REPO_DIR/}"
    fi
  done

  if [[ -z "$missing" ]]; then
    pass "profile routes and shared workflow are readable"
  else
    fail "profile subagent routes" "$missing"
  fi
}

test_coding_profile_preserves_ask_first_gates() {
  local missing
  missing="$(file_missing_markers \
    "$REPO_DIR/core/subagents/coding.md" \
    "core/subagents/coding.md" \
    "${CODING_PROFILE_ASK_FIRST_MARKERS[@]}")"

  if [[ -z "$missing" ]]; then
    pass "coding profile keeps ask-first gates"
  else
    fail "coding profile ask-first gates" "$missing"
  fi
}

test_review_profile_preserves_user_lens() {
  local missing
  missing="$(file_missing_markers \
    "$REPO_DIR/core/subagents/reviewing.md" \
    "core/subagents/reviewing.md" \
    "User goals, constraints, preferences" \
    "shared coordinator/worker contract")"

  if [[ -z "$missing" ]]; then
    pass "review keeps user and policy criteria"
  else
    fail "review user and policy criteria" "$missing"
  fi
}

test_commit_profile_message_and_permission_rules() {
  local missing
  missing="$(file_missing_markers \
    "$REPO_DIR/core/subagents/commit.md" \
    "core/subagents/commit.md" \
    "${COMMIT_PROFILE_MARKERS[@]}")"

  if [[ -z "$missing" ]]; then
    pass "commit profile keeps message and permission gates"
  else
    fail "commit profile message and permission rules" "$missing"
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
  # PATH symlinks should resolve the real repo.
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
  # Capture expected exit 1 without tripping pipefail.
  local output
  output="$(HOME="$TEST_HOME" "$INTERSECT" uninstall "$TEST_HOME/bin" 2>&1 || true)"
  if echo "$output" | grep -q "refusing"; then
    pass "uninstall refuses to remove foreign symlinks"
  else
    fail "uninstall safety" "should have refused; output: $output"
  fi
}

test_update_errors_when_repo_is_not_git() {
  # update should explain a missing .git/.
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
  # update should announce pull before any remote failure.
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

# Diagnostic Fixtures
create_diagnostic_stubs() {
  mkdir -p "$TEST_HOME/bin"
  cat > "$TEST_HOME/bin/provider" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
provider="${0##*/}"
source_file="$INTERSECT_TEST_REPO/core/agents.md"
if [[ "$provider" == codex ]]; then
  [[ "$#" -eq 7 && "$1" == exec && "$2" == --cd && "$4" == --skip-git-repo-check && "$5" == --output-last-message ]] || exit 42
  cd "$3"; answer_file="$6"; prompt="$7"
else
  [[ "$#" -eq 2 && "$1" == -p ]] || exit 42
  prompt="$2"
  [[ "$provider" != claude ]] || source_file="$INTERSECT_TEST_REPO/core/claude.md"
fi
[[ "$(<core/agents.md)" == '# Workspace Decoy Path' ]] || exit 42
IFS= read -r heading < "$INTERSECT_TEST_REPO/core/agents.md"
answer="$(printf '%s\n%s\n%s' "$source_file" "$INTERSECT_TEST_REPO/core/agents.md" "$heading")"
case "$INTERSECT_TEST_MODE" in
  echo) answer="$prompt" ;;
  decoy) answer="$(printf '%s\n%s\n%s' "$source_file" "$PWD/core/agents.md" '# Workspace Decoy Path')" ;;
  hang) sleep 30 & child=$!; printf '%s %s\n' "$$" "$child" > "$INTERSECT_TEST_PID"; wait; exit ;;
esac
if [[ "$provider" == codex ]]; then
  if [[ "$INTERSECT_TEST_MODE" != missing-final ]]; then printf '%s\n' "$answer" > "$answer_file"; fi
  printf '%s\n' 'Provider transcript noise' "$prompt"
else
  printf '%s\n' "$answer"
fi
[[ "$INTERSECT_TEST_MODE" != nonzero ]] || exit 7
STUB
  chmod +x "$TEST_HOME/bin/provider"
  for provider in claude codex gemini; do ln -s provider "$TEST_HOME/bin/$provider"; done
}

diagnostic_fixture() {
  local provider="$1" mode="$2" expected_status="$3" status=0 output line directory=''
  output="$(PATH="$TEST_HOME/bin:$PATH" TMPDIR="$TEST_HOME" \
    INTERSECT_TEST_REPO="$REPO_DIR" INTERSECT_TEST_MODE="$mode" INTERSECT_TEST_PID="$TEST_HOME/provider.pid" \
    INTERSECT_VERIFY_AI_TIMEOUT_SECONDS=1 /bin/bash "$REPO_DIR/test/verify-ai.sh" "$provider" 2>&1)" || status=$?
  while IFS= read -r line; do
    case "$line" in 'Diagnostic directory: '*) directory="${line#Diagnostic directory: }" ;; esac
  done <<< "$output"
  if [[ "$status" -ne "$expected_status" || -z "$directory" ]]; then
    fail "diagnostic $provider $mode" "status $status, expected $expected_status: $output"
  elif [[ "$status" -eq 0 && -e "$directory" ]]; then
    fail "diagnostic cleanup" "successful fixture retained $directory"
  elif [[ "$status" -ne 0 && ! -d "$directory/project" ]]; then
    fail "diagnostic failure evidence" "missing $directory/project"
  else
    pass "diagnostic $provider $mode (status $status)"
  fi
}

test_diagnostic_arguments() {
  local output status argument
  for argument in '' pickup paths behavior bogus 'paths codex' 'codex gemini'; do
    status=0
    if [[ "$argument" == *' '* ]]; then
      output="$(/bin/bash "$REPO_DIR/test/verify-ai.sh" "${argument%% *}" "${argument#* }" 2>&1)" || status=$?
    elif [[ -z "$argument" ]]; then
      output="$(/bin/bash "$REPO_DIR/test/verify-ai.sh" 2>&1)" || status=$?
    else
      output="$(/bin/bash "$REPO_DIR/test/verify-ai.sh" "$argument" 2>&1)" || status=$?
    fi
    if [[ "$status" -eq 2 && "$output" == *'Usage:'* ]]; then pass "diagnostic rejects '$argument'"; else fail "diagnostic arguments" "$output"; fi
  done
  status=0
  output="$(PATH="$TEST_HOME" /bin/bash "$REPO_DIR/test/verify-ai.sh" codex 2>&1)" || status=$?
  if [[ "$status" -eq 127 && "$output" == *'command not found'* ]]; then pass "diagnostic missing provider"; else fail "diagnostic missing provider" "$output"; fi
  status=0
  output="$(PATH="$TEST_HOME/bin:$PATH" INTERSECT_VERIFY_AI_TIMEOUT_SECONDS=0 /bin/bash "$REPO_DIR/test/verify-ai.sh" codex 2>&1)" || status=$?
  if [[ "$status" -eq 2 && "$output" == *'positive integer'* ]]; then pass "diagnostic invalid timeout"; else fail "diagnostic invalid timeout" "$output"; fi
}

test_diagnostic_interruption() {
  local diagnostic_pid status=0 attempts=0 provider_pid child_pid
  rm -f "$TEST_HOME/provider.pid"
  set -m
  PATH="$TEST_HOME/bin:$PATH" TMPDIR="$TEST_HOME" INTERSECT_TEST_REPO="$REPO_DIR" \
    INTERSECT_TEST_MODE=hang INTERSECT_TEST_PID="$TEST_HOME/provider.pid" \
    /bin/bash "$REPO_DIR/test/verify-ai.sh" codex > "$TEST_HOME/interruption.log" 2>&1 &
  diagnostic_pid=$!
  set +m
  while [[ ! -s "$TEST_HOME/provider.pid" && "$attempts" -lt 100 ]]; do sleep 0.1; attempts=$((attempts + 1)); done
  kill -TERM "$diagnostic_pid" 2>/dev/null || true
  wait "$diagnostic_pid" || status=$?
  if [[ ! -s "$TEST_HOME/provider.pid" ]]; then fail "diagnostic interruption" 'provider did not start'; return; fi
  read -r provider_pid child_pid < "$TEST_HOME/provider.pid"
  if [[ "$status" -eq 143 ]] && ! kill -0 "$provider_pid" 2>/dev/null && ! kill -0 "$child_pid" 2>/dev/null \
      && grep -Fq 'Diagnostic files retained:' "$TEST_HOME/interruption.log"; then
    pass "diagnostic interruption stops provider and child, retains evidence"
  else
    fail "diagnostic interruption" "exit $status or surviving process $provider_pid/$child_pid"
  fi
}

test_diagnostic_fixtures() {
  fresh_home
  create_diagnostic_stubs
  test_diagnostic_arguments
  diagnostic_fixture claude success 0
  diagnostic_fixture codex success 0
  diagnostic_fixture gemini success 0
  diagnostic_fixture codex echo 1
  diagnostic_fixture claude decoy 1
  diagnostic_fixture gemini nonzero 7
  diagnostic_fixture codex missing-final 1
  diagnostic_fixture codex hang 124
  test_diagnostic_interruption
}

# === Run All ===

test_markdown_headings_use_title_case
test_link_creates_declared_symlink_map
test_profile_routes_point_to_existing_files
test_coding_profile_preserves_ask_first_gates
test_review_profile_preserves_user_lens
test_commit_profile_message_and_permission_rules
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

test_diagnostic_fixtures

echo ""
echo "Passed: $PASSED, Failed: $FAILED"
exit "$FAILED"

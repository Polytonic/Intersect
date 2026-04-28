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

# fresh_home should reset $TEST_HOME between tests so state from one
# test never leaks into the next. Keeps tests independent.
fresh_home() {
  rm -rf "$TEST_HOME"
  mkdir -p "$TEST_HOME"
}

# === Tests ===

test_link_creates_expected_symlinks() {
  fresh_home
  HOME="$TEST_HOME" "$INTERSECT" link >/dev/null
  local actual expected
  actual="$(readlink "$TEST_HOME/.claude/CLAUDE.md")"
  expected="$REPO_DIR/core/claude.md"
  if [[ "$actual" == "$expected" ]]; then
    pass "link creates ~/.claude/CLAUDE.md → core/claude.md"
  else
    fail "link target" "expected $expected, got $actual"
  fi
}

test_link_creates_settings_symlinks() {
  fresh_home
  HOME="$TEST_HOME" "$INTERSECT" link >/dev/null
  local actual expected
  actual="$(readlink "$TEST_HOME/.codex/config.toml")"
  expected="$REPO_DIR/tools/codex/config.toml"
  if [[ "$actual" == "$expected" ]]; then
    pass "link creates ~/.codex/config.toml → tools/codex/config.toml"
  else
    fail "settings target" "expected $expected, got $actual"
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
  # This test catches the REPO_DIR-via-symlink bug we hit when installing the
  # CLI to /opt/homebrew/bin: the script was using the symlink's parent dir
  # instead of resolving through the symlink to the actual repo.
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
test_link_is_idempotent
test_link_per_tool_filtering
test_unlink_refuses_to_remove_real_files
test_unlink_removes_only_our_symlinks
test_install_through_symlink_resolves_repo_dir
test_install_is_idempotent
test_uninstall_refuses_to_remove_foreign_symlinks
test_unknown_command_errors_cleanly
test_unknown_tool_errors_cleanly

echo ""
echo "Passed: $PASSED, Failed: $FAILED"
exit "$FAILED"

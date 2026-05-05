#!/usr/bin/env bash
set -euo pipefail

# Configuration

EXPECTED_MARKER="# Coordinator Profile"
KNOWN_TOOLS=("claude" "codex" "gemini")
SELECTED_TOOLS=()

TEMP_PROJECT=""
PASS_COUNT=0
SKIP_COUNT=0
FAIL_COUNT=0


# Argument Handling

print_usage() {
  printf 'Usage: %s [claude] [codex] [gemini]\n' "$0" >&2
}

is_known_tool() {
  local tool="$1"

  case "$tool" in
    claude | codex | gemini)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

select_tools() {
  local tool

  if [[ "$#" -eq 0 ]]; then
    SELECTED_TOOLS=("${KNOWN_TOOLS[@]}")
    return
  fi

  for tool in "$@"; do
    if ! is_known_tool "$tool"; then
      printf 'fail unknown tool: %s\n' "$tool" >&2
      print_usage
      exit 2
    fi
    SELECTED_TOOLS+=("$tool")
  done
}


# Reporting

record_pass() {
  local tool="$1"

  printf 'pass %s: found %s\n' "$tool" "$EXPECTED_MARKER"
  PASS_COUNT=$((PASS_COUNT + 1))
}

record_skip() {
  local tool="$1"

  printf 'skip %s: command not found\n' "$tool"
  SKIP_COUNT=$((SKIP_COUNT + 1))
}

record_fail() {
  local tool="$1"
  local reason="$2"

  printf 'fail %s: %s\n' "$tool" "$reason" >&2
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

print_summary() {
  printf 'summary: %d passed, %d skipped, %d failed\n' "$PASS_COUNT" "$SKIP_COUNT" "$FAIL_COUNT"
}

contains_expected_marker() {
  local output="$1"

  case "$output" in
    *"$EXPECTED_MARKER"*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}


# Temp Project

create_temp_project() {
  TEMP_PROJECT="$(mktemp -d "${TMPDIR:-/tmp}/intersect-ai-verify.XXXXXX")"
}

cleanup_temp_project() {
  if [[ -n "$TEMP_PROJECT" && -d "$TEMP_PROJECT" ]]; then
    rm -rf "$TEMP_PROJECT"
  fi
}


# Tool Checks

check_claude() {
  local output_file="$TEMP_PROJECT/claude.output"
  local status=0
  local output

  if ! command -v claude >/dev/null 2>&1; then
    record_skip "claude"
    return
  fi

  (
    cd "$TEMP_PROJECT"
    claude -p "H1 of your global preferences file? Answer with only the H1."
  ) >"$output_file" 2>&1 || status=$?

  output="$(<"$output_file")"
  if [[ "$status" -eq 0 ]] && contains_expected_marker "$output"; then
    record_pass "claude"
    return
  fi

  if [[ "$status" -ne 0 ]]; then
    record_fail "claude" "command exited with status $status"
    return
  fi

  record_fail "claude" "missing $EXPECTED_MARKER"
}

check_codex() {
  local output_file="$TEMP_PROJECT/codex-last-message.txt"
  local command_output_file="$TEMP_PROJECT/codex.output"
  local status=0
  local output

  if ! command -v codex >/dev/null 2>&1; then
    record_skip "codex"
    return
  fi

  codex exec \
    --cd "$TEMP_PROJECT" \
    --skip-git-repo-check \
    --output-last-message "$output_file" \
    "H1 of ~/.codex/AGENTS.md, no preamble" \
    >"$command_output_file" 2>&1 || status=$?

  if [[ -s "$output_file" ]]; then
    output="$(<"$output_file")"
  else
    output="$(<"$command_output_file")"
  fi

  if [[ "$status" -eq 0 ]] && contains_expected_marker "$output"; then
    record_pass "codex"
    return
  fi

  if [[ "$status" -ne 0 ]]; then
    record_fail "codex" "command exited with status $status"
    return
  fi

  record_fail "codex" "missing $EXPECTED_MARKER"
}

check_gemini() {
  local output_file="$TEMP_PROJECT/gemini.output"
  local status=0
  local output

  if ! command -v gemini >/dev/null 2>&1; then
    record_skip "gemini"
    return
  fi

  (
    cd "$TEMP_PROJECT"
    gemini -p "H1 of ~/.gemini/GEMINI.md. Answer with only the H1."
  ) >"$output_file" 2>&1 || status=$?

  output="$(<"$output_file")"
  if [[ "$status" -eq 0 ]] && contains_expected_marker "$output"; then
    record_pass "gemini"
    return
  fi

  if [[ "$status" -ne 0 ]]; then
    record_fail "gemini" "command exited with status $status"
    return
  fi

  record_fail "gemini" "missing $EXPECTED_MARKER"
}

run_check() {
  local tool="$1"

  case "$tool" in
    claude)
      check_claude
      ;;
    codex)
      check_codex
      ;;
    gemini)
      check_gemini
      ;;
  esac
}


# Main

select_tools "$@"
create_temp_project
trap cleanup_temp_project EXIT

printf 'live AI verification from temp project: %s\n' "$TEMP_PROJECT"

for tool in "${SELECTED_TOOLS[@]}"; do
  run_check "$tool"
done

print_summary

if [[ "$FAIL_COUNT" -ne 0 ]]; then
  exit 1
fi

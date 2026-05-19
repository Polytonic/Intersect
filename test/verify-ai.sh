#!/usr/bin/env bash
set -euo pipefail

# Configuration

EXPECTED_PICKUP_MARKER="Coordinator"
EXPECTED_PATHS_MARKER="Coordinator"
DECOY_PATHS_MARKER="Workspace Decoy Path"
KNOWN_MODES=("pickup" "behavior" "paths")
KNOWN_TOOLS=("claude" "codex" "gemini")
SELECTED_MODE="pickup"
SELECTED_TOOLS=()
DETECTED_TOOLS=()
COMMAND_TIMEOUT_SECONDS="${INTERSECT_VERIFY_AI_TIMEOUT_SECONDS:-90}"

TEMP_PROJECT=""
TEMP_LOG_DIR=""
PASS_COUNT=0
SKIP_COUNT=0
FAIL_COUNT=0

BEHAVIOR_PROMPT=$(cat <<'PROMPT'
Synthetic profile-recognition and format check only. This is not an active
implementation request and not a real coordinator workflow.

Do not use tools, inspect files, run commands, launch subagents or agents, or
modify workspace state. Do not describe actions as completed. Produce a compact
static template that demonstrates the required labels and phrases.

Return only these sections:
- Brief fields
- Subagent returns
- Consultation policy
- Escalation criteria

Required exact words/phrases:
- Role
- Goal
- Task
- Context
- Scope
- Inputs
- Outputs
- Examples
- Done when
- Downstream
- Reasoning
- Changed/found
- Verified
- Consulted
- Questions/blockers
- Residual risk
- User lens
- same dimension
- fails twice

Every subagent brief must include these fields in order: "Role:", "Goal:",
"Task:", "Context:", "Scope:", "Inputs:", "Outputs:", "Examples:",
"Done when:", "Downstream:", and "Reasoning:".
Every subagent return must include "Changed/found:", "Verified:", "Consulted:",
"Questions/blockers:", and "Residual risk:" fields. Consultation policy must
name the User lens. Escalation criteria must include the exact phrases "same
dimension" and "fails twice".
PROMPT
)

PATHS_PROMPT=$(cat <<'PROMPT'
Resolve profile:core/agents.md from the active Intersect profile, not from the active workspace. Answer with only the first H1 text from that profile-owned file. Do not read core/subagents/*.md.
PROMPT
)

REQUIRED_BEHAVIOR_SUBSTRINGS=(
  "Role"
  "Goal"
  "Task"
  "Context"
  "Scope"
  "Inputs"
  "Outputs"
  "Examples"
  "Done when"
  "Downstream"
  "Reasoning"
  "Changed/found"
  "Verified"
  "Consulted"
  "Questions/blockers"
  "Residual risk"
  "User lens"
  "same dimension"
  "fails twice"
)

REQUIRED_BEHAVIOR_SECTIONS=(
  "Brief fields"
  "Subagent returns"
  "Consultation policy"
  "Escalation criteria"
)

REQUIRED_BEHAVIOR_STRUCTURES=(
  "Role:"
  "Goal:"
  "Task:"
  "Context:"
  "Scope:"
  "Inputs:"
  "Outputs:"
  "Examples:"
  "Done when:"
  "Downstream:"
  "Reasoning:"
  "Changed/found:"
  "Verified:"
  "Consulted:"
  "Questions/blockers:"
  "Residual risk:"
)


# Argument Handling

print_usage() {
  cat >&2 <<USAGE
Usage:
  $0 [pickup|behavior|paths] [claude|codex|gemini]...
  $0 [claude|codex|gemini]...

Default mode is pickup. With no tool arguments, the script detects the current CLI and runs only that tool.
Cross-tool diagnostics require explicit tool names.
Examples:
  $0
  $0 behavior
  $0 pickup codex
  $0 behavior claude
  $0 paths claude codex gemini
USAGE
}

is_known_mode() {
  local mode="$1"

  case "$mode" in
    pickup | behavior | paths)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
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

has_env_var() {
  local name="$1"

  [[ -n "${!name+x}" ]]
}

has_any_env_var() {
  local name

  for name in "$@"; do
    if has_env_var "$name"; then
      return 0
    fi
  done

  return 1
}

environment_indicates_tool() {
  local tool="$1"

  case "$tool" in
    claude)
      has_any_env_var \
        CLAUDECODE \
        CLAUDE_CODE_ENTRYPOINT \
        CLAUDE_CODE_SESSION_ID \
        CLAUDE_CODE_SHELL_PREFIX
      ;;
    codex)
      has_any_env_var \
        CODEX_THREAD_ID \
        CODEX_SANDBOX \
        CODEX_INTERNAL_ORIGINATOR_OVERRIDE \
        CODEX_CI
      ;;
    gemini)
      has_any_env_var \
        GEMINI_CLI \
        GEMINI_CLI_ENV \
        GEMINI_CLI_SESSION_ID
      ;;
    *)
      return 1
      ;;
  esac
}

detect_current_tools() {
  local tool

  DETECTED_TOOLS=()
  for tool in "${KNOWN_TOOLS[@]}"; do
    if environment_indicates_tool "$tool"; then
      DETECTED_TOOLS+=("$tool")
    fi
  done
}

select_current_tool_or_exit() {
  detect_current_tools

  if [[ "${#DETECTED_TOOLS[@]}" -eq 1 ]]; then
    SELECTED_TOOLS=("${DETECTED_TOOLS[0]}")
    return
  fi

  if [[ "${#DETECTED_TOOLS[@]}" -gt 1 ]]; then
    printf 'fail ambiguous current CLI environment: ' >&2
    print_joined_labels "${DETECTED_TOOLS[@]}" >&2
    printf '\n' >&2
  else
    printf 'fail no explicit tool supplied and current CLI was not detected from environment\n' >&2
  fi

  print_usage
  exit 2
}

select_mode_and_tools() {
  local arg

  if [[ "$#" -gt 0 ]] && is_known_mode "$1"; then
    SELECTED_MODE="$1"
    shift
  fi

  if [[ "$#" -eq 0 ]]; then
    select_current_tool_or_exit
    return
  fi

  for arg in "$@"; do
    if ! is_known_tool "$arg"; then
      printf 'fail unknown argument: %s\n' "$arg" >&2
      print_usage
      exit 2
    fi
    SELECTED_TOOLS+=("$arg")
  done
}

is_positive_integer() {
  local value="$1"

  case "$value" in
    "" | *[!0123456789]*)
      return 1
      ;;
  esac

  [[ "$value" -gt 0 ]]
}

validate_timeout_config() {
  if is_positive_integer "$COMMAND_TIMEOUT_SECONDS"; then
    return
  fi

  printf 'fail invalid INTERSECT_VERIFY_AI_TIMEOUT_SECONDS: %s\n' "$COMMAND_TIMEOUT_SECONDS" >&2
  printf 'INTERSECT_VERIFY_AI_TIMEOUT_SECONDS must be a positive integer number of seconds.\n' >&2
  print_usage
  exit 2
}


# Reporting

record_pass() {
  local mode="$1"
  local tool="$2"
  local message="$3"

  printf 'pass %s %s: %s\n' "$mode" "$tool" "$message"
  PASS_COUNT=$((PASS_COUNT + 1))
}

record_skip() {
  local tool="$1"

  printf 'skip %s: command not found\n' "$tool"
  SKIP_COUNT=$((SKIP_COUNT + 1))
}

record_fail() {
  local mode="$1"
  local tool="$2"
  local reason="$3"
  local log_path="$4"

  printf 'fail %s %s: %s\n' "$mode" "$tool" "$reason" >&2
  printf '  log: %s\n' "$log_path" >&2
  printf '  log directory preserved: %s\n' "$TEMP_LOG_DIR" >&2
  printf '  temp project preserved: %s\n' "$TEMP_PROJECT" >&2
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

print_summary() {
  printf 'summary: %d passed, %d skipped, %d failed\n' "$PASS_COUNT" "$SKIP_COUNT" "$FAIL_COUNT"
}


# Text Checks

contains_text() {
  local output="$1"
  local expected="$2"

  case "$output" in
    *"$expected"*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

missing_behavior_substrings() {
  local output="$1"
  local substring
  local missing=()

  for substring in "${REQUIRED_BEHAVIOR_SUBSTRINGS[@]}"; do
    if ! contains_text "$output" "$substring"; then
      missing+=("$substring")
    fi
  done

  if [[ "${#missing[@]}" -eq 0 ]]; then
    return
  fi

  print_joined_labels "${missing[@]}"
}

missing_behavior_structures() {
  local output="$1"
  local label
  local missing=()

  for label in "${REQUIRED_BEHAVIOR_SECTIONS[@]}"; do
    if ! contains_text "$output" "$label"; then
      missing+=("section label: $label")
    fi
  done

  for label in "${REQUIRED_BEHAVIOR_STRUCTURES[@]}"; do
    if ! contains_text "$output" "$label"; then
      missing+=("$label")
    fi
  done

  if [[ "${#missing[@]}" -eq 0 ]]; then
    return
  fi

  print_joined_labels "${missing[@]}"
}

print_joined_labels() {
  if [[ "$#" -eq 0 ]]; then
    return
  fi

  printf '%s' "$1"
  shift

  while [[ "$#" -gt 0 ]]; do
    printf ', %s' "$1"
    shift
  done
}

canonical_heading_marker_found() {
  local output="$1"
  local expected="$2"
  local line
  local normalized

  while IFS= read -r line || [[ -n "$line" ]]; do
    normalized="$line"

    while [[ "$normalized" == " "* || "$normalized" == $'\t'* ]]; do
      normalized="${normalized#"${normalized:0:1}"}"
    done

    while [[ "$normalized" == *" " || "$normalized" == *$'\t' ]]; do
      normalized="${normalized%"${normalized: -1}"}"
    done

    if [[ "${#normalized}" -ge 2 && "${normalized:0:1}" == "\`" && "${normalized: -1}" == "\`" ]]; then
      normalized="${normalized:1:${#normalized}-2}"
    fi

    while [[ "$normalized" == " "* || "$normalized" == $'\t'* ]]; do
      normalized="${normalized#"${normalized:0:1}"}"
    done

    while [[ "$normalized" == *" " || "$normalized" == *$'\t' ]]; do
      normalized="${normalized%"${normalized: -1}"}"
    done

    while [[ "$normalized" == "#"* ]]; do
      normalized="${normalized#"#"}"
    done

    while [[ "$normalized" == " "* || "$normalized" == $'\t'* ]]; do
      normalized="${normalized#"${normalized:0:1}"}"
    done

    while [[ "$normalized" == *" " || "$normalized" == *$'\t' ]]; do
      normalized="${normalized%"${normalized: -1}"}"
    done

    if [[ "$normalized" == "$expected" ]]; then
      return 0
    fi
  done <<<"$output"

  return 1
}

canonical_pickup_marker_found() {
  local output="$1"

  canonical_heading_marker_found "$output" "$EXPECTED_PICKUP_MARKER"
}

canonical_paths_marker_found() {
  local output="$1"

  canonical_heading_marker_found "$output" "$EXPECTED_PATHS_MARKER"
}

lowercase_text() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

classify_failure() {
  local status="$1"
  local output="$2"
  local lowered

  if [[ "$status" -eq 124 ]]; then
    printf 'timeout after %ss' "$COMMAND_TIMEOUT_SECONDS"
    return
  fi

  lowered="$(lowercase_text "$output")"
  case "$lowered" in
    *"not logged in"* | *"login"* | *"authentication"* | *"api key"* | *"unauthorized"*)
      printf 'auth/login'
      ;;
    *"permission denied"* | *"operation not permitted"* | *"session"* | *"sandbox"* | *"access denied"*)
      printf 'permission/session-state'
      ;;
    *)
      printf 'command exited with status %s' "$status"
      ;;
  esac
}


# Temp Paths

create_temp_project() {
  TEMP_PROJECT="$(mktemp -d "${TMPDIR:-/tmp}/intersect-ai-verify.XXXXXX")"
}

create_temp_log_dir() {
  TEMP_LOG_DIR="$(mktemp -d "${TMPDIR:-/tmp}/intersect-ai-verify-logs.XXXXXX")"
}

create_paths_decoy() {
  mkdir -p "$TEMP_PROJECT/core"
  printf '# %s\n' "$DECOY_PATHS_MARKER" >"$TEMP_PROJECT/core/agents.md"
}

prepare_temp_project_for_mode() {
  if [[ "$SELECTED_MODE" == "paths" ]]; then
    create_paths_decoy
  fi
}

cleanup_temp_paths_on_success() {
  local status="$?"

  if [[ "$status" -eq 0 && "$FAIL_COUNT" -eq 0 && -n "$TEMP_PROJECT" && -d "$TEMP_PROJECT" ]]; then
    rm -rf "$TEMP_PROJECT"
  fi

  if [[ "$status" -eq 0 && "$FAIL_COUNT" -eq 0 && -n "$TEMP_LOG_DIR" && -d "$TEMP_LOG_DIR" ]]; then
    rm -rf "$TEMP_LOG_DIR"
  fi
}


# Command Execution

run_with_timeout() {
  local output_file="$1"
  shift
  local use_process_group=0

  if command -v setsid >/dev/null 2>&1; then
    setsid "$@" >"$output_file" 2>&1 &
    use_process_group=1
  else
    "$@" >"$output_file" 2>&1 &
  fi
  local command_pid=$!
  local start_seconds=$SECONDS

  while kill -0 "$command_pid" 2>/dev/null; do
    if (( SECONDS - start_seconds >= COMMAND_TIMEOUT_SECONDS )); then
      if [[ "$use_process_group" -eq 1 ]]; then
        kill -- "-$command_pid" 2>/dev/null || true
      fi
      kill "$command_pid" 2>/dev/null || true
      sleep 1
      if [[ "$use_process_group" -eq 1 ]]; then
        kill -9 -- "-$command_pid" 2>/dev/null || true
      fi
      kill -9 "$command_pid" 2>/dev/null || true
      wait "$command_pid" 2>/dev/null || true
      printf '\n[intersect verify-ai] timed out after %ss\n' "$COMMAND_TIMEOUT_SECONDS" >>"$output_file"
      return 124
    fi
    sleep 1
  done

  wait "$command_pid"
}

run_in_temp_project() {
  local output_file="$1"
  shift

  (
    cd "$TEMP_PROJECT"
    run_with_timeout "$output_file" "$@"
  )
}

read_file_if_present() {
  local file="$1"

  if [[ -f "$file" ]]; then
    printf '%s' "$(<"$file")"
  fi
}


# Tool Commands

run_claude() {
  local prompt="$1"
  local output_file="$2"

  run_in_temp_project "$output_file" claude -p "$prompt"
}

run_codex() {
  local prompt="$1"
  local output_file="$2"
  local last_message_file="$3"

  run_with_timeout "$output_file" \
    codex exec \
      --cd "$TEMP_PROJECT" \
      --skip-git-repo-check \
      --output-last-message "$last_message_file" \
      "$prompt"
}

run_gemini() {
  local prompt="$1"
  local output_file="$2"

  run_in_temp_project "$output_file" gemini -p "$prompt"
}

tool_prompt_for_mode() {
  local mode="$1"
  local tool="$2"

  if [[ "$mode" == "behavior" ]]; then
    printf '%s' "$BEHAVIOR_PROMPT"
    return
  fi

  if [[ "$mode" == "paths" ]]; then
    printf '%s' "$PATHS_PROMPT"
    return
  fi

  case "$tool" in
    claude)
      printf 'H1 of your global preferences file? Answer with only the H1.'
      ;;
    codex)
      printf 'H1 of ~/.codex/AGENTS.md, no preamble'
      ;;
    gemini)
      printf 'H1 of ~/.gemini/GEMINI.md. Answer with only the H1.'
      ;;
  esac
}


# Mode Checks

check_pickup_output() {
  local tool="$1"
  local status="$2"
  local output="$3"
  local log_path="$4"
  local reason

  if [[ "$status" -eq 0 ]] && canonical_pickup_marker_found "$output"; then
    record_pass "pickup" "$tool" "found $EXPECTED_PICKUP_MARKER"
    return
  fi

  if [[ "$status" -ne 0 ]]; then
    reason="$(classify_failure "$status" "$output")"
    record_fail "pickup" "$tool" "$reason" "$log_path"
    return
  fi

  record_fail "pickup" "$tool" "missing marker: $EXPECTED_PICKUP_MARKER" "$log_path"
}

check_behavior_output() {
  local tool="$1"
  local status="$2"
  local output="$3"
  local log_path="$4"
  local missing
  local missing_structure
  local reason

  if [[ "$status" -ne 0 ]]; then
    reason="$(classify_failure "$status" "$output")"
    record_fail "behavior" "$tool" "$reason" "$log_path"
    return
  fi

  missing="$(missing_behavior_substrings "$output")"
  if [[ -n "$missing" ]]; then
    record_fail "behavior" "$tool" "missing assertion substring(s): $missing" "$log_path"
    return
  fi

  missing_structure="$(missing_behavior_structures "$output")"
  if [[ -n "$missing_structure" ]]; then
    record_fail "behavior" "$tool" "missing structural assertion(s): $missing_structure" "$log_path"
    return
  fi

  record_pass "behavior" "$tool" "found required substrings and structure"
}

check_paths_output() {
  local tool="$1"
  local status="$2"
  local output="$3"
  local log_path="$4"
  local reason

  if [[ "$status" -ne 0 ]]; then
    reason="$(classify_failure "$status" "$output")"
    record_fail "paths" "$tool" "$reason" "$log_path"
    return
  fi

  if contains_text "$output" "$DECOY_PATHS_MARKER"; then
    record_fail "paths" "$tool" "resolved workspace decoy: $DECOY_PATHS_MARKER" "$log_path"
    return
  fi

  if canonical_paths_marker_found "$output"; then
    record_pass "paths" "$tool" "found profile marker: $EXPECTED_PATHS_MARKER"
    return
  fi

  record_fail "paths" "$tool" "missing profile marker: $EXPECTED_PATHS_MARKER" "$log_path"
}

check_tool() {
  local tool="$1"
  local prompt
  local output_file="$TEMP_LOG_DIR/$SELECTED_MODE-$tool.output"
  local last_message_file="$TEMP_LOG_DIR/$SELECTED_MODE-$tool-last-message.txt"
  local status=0
  local output

  if ! command -v "$tool" >/dev/null 2>&1; then
    record_skip "$tool"
    return
  fi

  prompt="$(tool_prompt_for_mode "$SELECTED_MODE" "$tool")"

  case "$tool" in
    claude)
      run_claude "$prompt" "$output_file" || status=$?
      output="$(read_file_if_present "$output_file")"
      ;;
    codex)
      run_codex "$prompt" "$output_file" "$last_message_file" || status=$?
      if [[ -s "$last_message_file" ]]; then
        output="$(read_file_if_present "$last_message_file")"
      else
        output="$(read_file_if_present "$output_file")"
      fi
      ;;
    gemini)
      run_gemini "$prompt" "$output_file" || status=$?
      output="$(read_file_if_present "$output_file")"
      ;;
  esac

  case "$SELECTED_MODE" in
    pickup)
      check_pickup_output "$tool" "$status" "$output" "$output_file"
      ;;
    behavior)
      check_behavior_output "$tool" "$status" "$output" "$output_file"
      ;;
    paths)
      check_paths_output "$tool" "$status" "$output" "$output_file"
      ;;
  esac
}


# Main

validate_timeout_config
select_mode_and_tools "$@"
create_temp_project
create_temp_log_dir
prepare_temp_project_for_mode
trap cleanup_temp_paths_on_success EXIT

printf 'live AI verification mode: %s\n' "$SELECTED_MODE"
printf 'live AI verification tool(s): %s\n' "${SELECTED_TOOLS[*]}"
printf 'live AI verification from temp project: %s\n' "$TEMP_PROJECT"
printf 'live AI verification logs: %s\n' "$TEMP_LOG_DIR"
printf 'per-tool timeout: %ss\n' "$COMMAND_TIMEOUT_SECONDS"

for tool in "${SELECTED_TOOLS[@]}"; do
  check_tool "$tool"
done

print_summary

if [[ "$FAIL_COUNT" -ne 0 ]]; then
  exit 1
fi

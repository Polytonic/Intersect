#!/usr/bin/env bash
set -euo pipefail

# Arguments
usage() {
  printf 'Usage: %s <claude|codex|gemini>\n' "$0" >&2
  printf 'Optional live profile-loading diagnostic; old pickup/paths/behavior modes are removed.\n' >&2
}

if [[ "$#" -ne 1 ]]; then
  usage
  exit 2
fi
tool="$1"
case "$tool" in
  claude|codex|gemini) ;;
  *) printf 'Unknown provider: %s\n' "$tool" >&2; usage; exit 2 ;;
esac
if ! command -v "$tool" >/dev/null 2>&1; then
  printf 'Provider command not found: %s\n' "$tool" >&2
  exit 127
fi
timeout_seconds="${INTERSECT_VERIFY_AI_TIMEOUT_SECONDS:-90}"
case "$timeout_seconds" in
  ''|*[!0-9]*) printf 'Timeout must be a positive integer in seconds.\n' >&2; exit 2 ;;
esac
if ! [ "$timeout_seconds" -gt 0 ] 2>/dev/null; then
  printf 'Timeout must be a positive integer in seconds.\n' >&2
  exit 2
fi
timeout_seconds=$((10#$timeout_seconds))

# Diagnostic Inputs
repo_dir="$(cd "$(dirname "$0")/.." && pwd -P)"
profile="$repo_dir/core/agents.md"
IFS= read -r heading < "$profile"
source_file="$profile"
case "$tool" in
  claude) preferences='~/.claude/CLAUDE.md'; source_file="$repo_dir/core/claude.md" ;;
  codex) preferences='~/.codex/AGENTS.md' ;;
  gemini) preferences='~/.gemini/GEMINI.md' ;;
esac
prompt="Terminal consultation: yes
Persona: Profile-loading diagnostician.
Question: Read $preferences and resolve its symlink to the physical source file. From that source's profile root, resolve and read profile:core/agents.md. The workspace contains a decoy.
Scope: Read-only local inspection. No delegation, descendants, edits, or other external services.
Expected return: Exactly three lines: the absolute physical path of the global preferences source, the absolute physical path of the resolved profile file, and that profile's first H1 line including its leading #. No code fences or commentary. If a required file is unavailable, report the failure instead."
expected="$(printf '%s\n%s\n%s' "$source_file" "$profile" "$heading")"

# Process And Artifact Cleanup
provider_pid=''
artifacts="$(mktemp -d "${TMPDIR:-/tmp}/intersect-ai-verify.XXXXXX")"
cleanup() {
  local status=$?
  trap - EXIT INT TERM
  if [[ -n "$provider_pid" ]] && kill -TERM -- "-$provider_pid" 2>/dev/null; then
    sleep 1
    kill -KILL -- "-$provider_pid" 2>/dev/null || true
  fi
  if [[ -n "$provider_pid" ]]; then wait "$provider_pid" 2>/dev/null || true; fi
  if [[ "$status" -eq 0 ]]; then
    rm -rf "$artifacts"
  else
    printf 'Diagnostic files retained: %s\n' "$artifacts" >&2
    printf 'Inspect response.txt and provider.log for output, authentication, sandbox, or provider errors.\n' >&2
  fi
  exit "$status"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
mkdir -p "$artifacts/project/core"
printf '# Workspace Decoy Path\n' > "$artifacts/project/core/agents.md"
printf 'Optional live diagnostic: %s (timeout %ss)\n' "$tool" "$timeout_seconds"
printf 'Diagnostic directory: %s\n' "$artifacts"

# Provider Execution
# Job control gives this provider its own process group for timeout and interruption cleanup.
set -m
case "$tool" in
  codex)
    (exec codex exec --cd "$artifacts/project" --skip-git-repo-check \
      --output-last-message "$artifacts/response.txt" "$prompt") > "$artifacts/provider.log" 2>&1 &
    ;;
  claude|gemini)
    (cd "$artifacts/project"; exec "$tool" -p "$prompt") > "$artifacts/response.txt" 2> "$artifacts/provider.log" &
    ;;
esac
provider_pid=$!
set +m
started=$SECONDS
while kill -0 "$provider_pid" 2>/dev/null; do
  if (( SECONDS - started >= timeout_seconds )); then
    printf 'Diagnostic timed out after %ss.\n' "$timeout_seconds" >&2
    exit 124
  fi
  sleep 1
done
status=0
wait "$provider_pid" || status=$?
if [[ "$status" -ne 0 ]]; then
  printf 'Provider %s exited with status %s.\n' "$tool" "$status" >&2
  exit "$status"
fi

# Reported Identity Check
if [[ ! -f "$artifacts/response.txt" ]] || [[ "$(<"$artifacts/response.txt")" != "$expected" ]]; then
  printf 'Profile-loading response did not match this checkout. Expected exactly:\n%s\n' "$expected" >&2
  exit 1
fi
printf 'Passed: %s reported the expected source, profile path, and heading.\n' "$tool"
printf 'This diagnostic does not prove actual file reads, delegation, or policy execution.\n'

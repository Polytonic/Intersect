#!/usr/bin/env zsh
# Claude Code statusline: context window, Claude rate limit, Codex rate limit.
set -euo pipefail
setopt EXTENDED_GLOB

zmodload zsh/datetime
export LC_ALL=en_US.UTF-8

WIDTH=10
GREEN=$'\e[32m' YELLOW=$'\e[33m' RED=$'\e[31m' DIM=$'\e[2m' RESET=$'\e[0m'
SEP=" ${DIM}•${RESET} "

# Helpers

is_integer() { [[ "${1:-}" == (|-)<-> ]]; }

color_for() {
  local pct=${1:-0}
  if (( pct >= 80 )); then print -n "$RED"
  elif (( pct >= 50 )); then print -n "$YELLOW"
  else print -n "$GREEN"; fi
}

fmt_reset() {
  local result
  # %l pads single-digit hours with a space (not zero); strip it
  if strftime -s result '%l:%M%p' "$1" 2>/dev/null; then
    print -n "${(L)${result# }}"
  fi
}

fmt_tokens() {
  local n=$1
  if (( n >= 1000000 )); then print -n "$(( n / 1000000 ))M"
  elif (( n >= 1000 )); then print -n "$(( n / 1000 ))k"
  else print -n "$n"; fi
}

progress() {
  local used=${1:-}
  used=${used%.*}
  if ! is_integer "$used"; then
    print -n "${DIM}??????????${RESET}"
    return
  fi
  if (( used < 0 )); then used=0; fi
  if (( used > 100 )); then used=100; fi
  local color=$(color_for "$used")
  local filled=$(( (used * WIDTH + 50) / 100 ))
  local empty=$(( WIDTH - filled ))
  local fill="" gap=""
  repeat $filled fill+="█"
  repeat $empty gap+="░"
  print -n "${color}${fill}${DIM}${gap}${RESET}"
}

rate_info() {
  local used=${1:-} reset=${2:-}
  used=${used%.*}
  if is_integer "$used"; then
    if (( used < 0 )); then used=0; fi
    if (( used > 100 )); then used=100; fi
    local color=$(color_for "$used")
    local info="${color}${used}%${RESET}"
    if is_integer "$reset"; then
      local reset_time=$(fmt_reset "$reset")
      if [[ -n "$reset_time" ]]; then
        local remaining=$(( reset - EPOCHSECONDS ))
        local time_color
        if (( remaining < 1800 )); then time_color=$GREEN
        elif (( remaining < 7200 )); then time_color=$YELLOW
        else time_color=$RED; fi
        info+=" ${DIM}|${RESET} ${time_color}reset ${reset_time}${RESET}"
      fi
    fi
    print -n "(${info})"
  else
    print -n "${DIM}(--)${RESET}"
  fi
}

visible_len() { print -n ${#${1//$'\e'\[[0-9;]##m}}; }

# Parse Stdin

payload=$(cat)
if ! command -v jq &>/dev/null || [[ -z "$payload" ]]; then
  print 'Claude [??????????] (--%)'
  exit 0
fi

IFS=$'\t' read -r context_pct context_size claude_used claude_reset <<< "$(
  print -r -- "$payload" | jq -r '[
    (.context_window.used_percentage // ""),
    (.context_window.context_window_size // ""),
    (.rate_limits.five_hour.used_percentage // ""),
    (.rate_limits.five_hour.resets_at // "")
  ] | @tsv' 2>/dev/null
)" || true
cols=${COLUMNS:-$(tput cols 2>/dev/null || print 120)}

# Context Window

context_pct=${context_pct%.*}
context_size=${context_size%.*}
if is_integer "$context_pct" && is_integer "$context_size" && (( context_size > 0 )); then
  if (( context_pct < 0 )); then context_pct=0; fi
  if (( context_pct > 100 )); then context_pct=100; fi
  context_used=$(( context_pct * context_size / 100 ))
  color=$(color_for "$context_pct")
  context="[$(progress "$context_pct")] (${color}${context_pct}%${RESET}) ($(fmt_tokens "$context_used")/$(fmt_tokens "$context_size"))"
else
  context="[$(progress)] ${DIM}(--)${RESET}"
fi

# Rate Limits

claude_bar=$(progress "$claude_used")
claude_full="Claude [${claude_bar}] $(rate_info "$claude_used" "$claude_reset")"
claude_compact="Claude [${claude_bar}] $(rate_info "$claude_used")"

codex_full="" codex_compact=""
if command -v codex &>/dev/null && [[ -d ~/.codex/sessions ]]; then
  codex_used="" codex_reset=""
  session_files=(~/.codex/sessions/*/*/*/*.jsonl(Nom[1]))
  latest=${session_files[1]}
  if [[ -f "$latest" ]]; then
    codex_line=$(tail -200 "$latest" | grep '"rate_limits"' | tail -1) || true
    if [[ -n "$codex_line" ]]; then
      IFS=$'\t' read -r codex_used codex_reset <<< "$(
        print -r -- "$codex_line" | jq -r '
          (.payload.rate_limits | if .primary.window_minutes == 300 then .primary
           elif .secondary.window_minutes == 300 then .secondary
           else .primary end) as $w |
          [($w.used_percent // ""), ($w.resets_at // "")]
          | @tsv' 2>/dev/null
      )" || true
    fi
  fi
  if is_integer "$codex_reset" && (( codex_reset < EPOCHSECONDS )); then
    codex_used="" codex_reset=""
  fi
  codex_bar=$(progress "$codex_used")
  codex_full="Codex [${codex_bar}] $(rate_info "$codex_used" "$codex_reset")"
  codex_compact="Codex [${codex_bar}] $(rate_info "$codex_used")"
fi

# Compose with Progressive Degradation

if [[ -n "$codex_full" ]]; then
  line="$context${SEP}$claude_full${SEP}$codex_full"
  if (( $(visible_len "$line") <= cols )); then
    print "$line"; exit 0
  fi
  line="$context${SEP}$claude_full${SEP}$codex_compact"
  if (( $(visible_len "$line") <= cols )); then
    print "$line"; exit 0
  fi
  line="$context${SEP}$claude_compact${SEP}$codex_compact"
  if (( $(visible_len "$line") <= cols )); then
    print "$line"; exit 0
  fi
fi

line="$context${SEP}$claude_full"
if (( $(visible_len "$line") <= cols )); then
  print "$line"; exit 0
fi

print "$context${SEP}$claude_compact"

#!/usr/bin/env zsh

set -euo pipefail

: "${MACOS_RESTART_FLAG_DIR:=/tmp/chezmoi-macos-restart-flags}"

typeset -A RESTART_COMMANDS=(
  Finder 'killall Finder 2>/dev/null || true'
  Dock 'killall Dock 2>/dev/null || true'
  SystemUIServer 'killall SystemUIServer 2>/dev/null || true'
  Safari 'killall Safari 2>/dev/null || true'
  Mail 'killall Mail 2>/dev/null || true'
  ActivityMonitor 'killall "Activity Monitor" 2>/dev/null || true'
  TextEdit 'killall TextEdit 2>/dev/null || true'
)

mkdir -p "$MACOS_RESTART_FLAG_DIR"

mark_restart_needed() {
  local service="$1"
  : > "${MACOS_RESTART_FLAG_DIR}/${service}"
}

restart_all_flagged() {
  local flag service

  setopt local_options null_glob
  for flag in "$MACOS_RESTART_FLAG_DIR"/*; do
    [[ -e "$flag" ]] || return 0
    service="${flag:t}"

    if [[ -n "${RESTART_COMMANDS[$service]:-}" ]]; then
      eval "${RESTART_COMMANDS[$service]}"
    else
      print -u2 "Unknown restart target: $service"
    fi
  done
}

clear_restart_flags() {
  rm -rf "$MACOS_RESTART_FLAG_DIR"
}

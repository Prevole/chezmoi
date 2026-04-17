#!/usr/bin/env zsh

set -euo pipefail

source "${HOME}/.local/share/chezmoi/scripts/macos-flags.zsh"

if [[ ! -d "$MACOS_RESTART_FLAG_DIR" ]]; then
  exit 0
fi

restart_all_flagged

clear_restart_flags

#!/usr/bin/env zsh

source "${HOME}/.local/share/chezmoi/scripts/macos-flags.zsh"

# Hot corner - top left
defaults write com.apple.dock wvous-tl-corner -int 13   # legacy kept
defaults write com.apple.dock wvous-tl-modifier -int 0  # legacy kept

# Modern equivalent:
# use UI: System Settings > Desktop & Dock > Hot Corners

mark_restart_needed Dock

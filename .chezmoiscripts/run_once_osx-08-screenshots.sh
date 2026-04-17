#!/usr/bin/env zsh

source "${HOME}/.local/share/chezmoi/scripts/macos-flags.zsh"

# Screenshots - disable window shadow
defaults write com.apple.screencapture disable-shadow -bool true  # ok

mark_restart_needed SystemUIServer

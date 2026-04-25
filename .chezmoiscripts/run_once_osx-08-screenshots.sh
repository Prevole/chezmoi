#!/usr/bin/env zsh

source "${HOME}/.local/share/chezmoi/scripts/macos-flags.zsh"

# Screenshots - save location
mkdir -p "${HOME}/Downloads/screenshots"
defaults write com.apple.screencapture location -string "${HOME}/Downloads/screenshots"  # ok

# Screenshots - format
defaults write com.apple.screencapture type -string "png"  # ok

# Screenshots - disable window shadow
defaults write com.apple.screencapture disable-shadow -bool true  # ok

mark_restart_needed SystemUIServer

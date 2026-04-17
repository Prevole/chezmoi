#!/usr/bin/env zsh

source "${HOME}/.local/share/chezmoi/scripts/macos-flags.zsh"

# Finder - show external drives on desktop
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true  # ok

# Finder - show hard drives on desktop
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool true          # ok

# Finder - show mounted servers on desktop
defaults write com.apple.finder ShowMountedServersOnDesktop -bool true      # ok

# Finder - show removable media on desktop
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true      # ok

mark_restart_needed Finder

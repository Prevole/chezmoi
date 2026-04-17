#!/usr/bin/env zsh

source "${HOME}/.local/share/chezmoi/scripts/macos-flags.zsh"

# Activity Monitor - open main window on launch
defaults write com.apple.ActivityMonitor OpenMainWindow -bool true      # ok

# Activity Monitor - Dock icon shows CPU usage
defaults write com.apple.ActivityMonitor IconType -int 5                # ok

# Activity Monitor - show all processes
defaults write com.apple.ActivityMonitor ShowCategory -int 0            # ok

# Activity Monitor - sort by CPU usage
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"  # ok
defaults write com.apple.ActivityMonitor SortDirection -int 0           # ok

mark_restart_needed ActivityMonitor

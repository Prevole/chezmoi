#!/usr/bin/env zsh

source "${HOME}/.local/share/chezmoi/scripts/macos-flags.zsh"

# Dock - show running app indicators
defaults write com.apple.dock show-process-indicators -bool true  # ok

# Mission Control - do not rearrange Spaces automatically
defaults write com.apple.dock mru-spaces -bool false              # ok

# Hot corner - bottom right
defaults write com.apple.dock wvous-br-corner -int 4              # legacy kept
defaults write com.apple.dock wvous-br-modifier -int 0            # legacy kept

# Dock - size and magnification
defaults write com.apple.dock tilesize -int 36                    # ok
defaults write com.apple.dock largesize -int 54                   # ok
defaults write com.apple.dock magnification -bool true            # ok

# Dock - minimize effect
defaults write com.apple.dock mineffect -string "scale"           # ok

# Dock - minimize into app icon
defaults write com.apple.dock minimize-to-application -bool true  # ok

# Dock - auto hide
defaults write com.apple.dock autohide -bool true                 # ok
defaults write com.apple.dock autohide-time-modifier -float 0.4   # legacy kept
defaults write com.apple.dock autohide-delay -float 0             # legacy kept

# Dock - hide recent apps
defaults write com.apple.dock show-recents -bool false            # ok

mark_restart_needed Dock

#!/usr/bin/env zsh

source "${HOME}/.local/share/chezmoi/scripts/macos-flags.zsh"

# Font smoothing on non-Apple displays
defaults write NSGlobalDomain AppleFontSmoothing -int 1                                              # legacy kept

# Enable HiDPI display modes
sudo defaults write /Library/Preferences/com.apple.windowserver DisplayResolutionEnabled -bool true  # legacy kept

# Finder - disable animations
defaults write com.apple.finder DisableAllAnimations -bool true                                      # legacy kept

# Finder - show path bar
defaults write com.apple.finder ShowPathbar -bool true                                               # ok

# Finder - show status bar
defaults write com.apple.finder ShowStatusBar -bool true                                             # ok

# Finder - show all filename extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true                                      # ok

# Finder - extension change warning
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false                           # ok

# Finder - iCloud Drive remove warning
defaults write com.apple.finder FXEnableRemoveFromICloudDriveWarning -bool false                     # legacy kept

mark_restart_needed Finder

#!/usr/bin/env zsh

source "${HOME}/.local/share/chezmoi/scripts/macos-flags.zsh"

# Keyboard - key repeat rate
defaults write NSGlobalDomain KeyRepeat -float 2                                 # ok
defaults write NSGlobalDomain InitialKeyRepeat -float 15                         # ok

# Input sources - show input menu in menu bar
defaults write com.apple.TextInputMenu visible -bool true                        # legacy kept

# Keyboard navigation / full keyboard access
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3                         # ok

# Text input - disable auto correction features
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false   # ok
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false       # ok
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false     # ok
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false   # ok
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false    # ok

# Keyboard - prefer key repeat over press-and-hold
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false               # ok

mark_restart_needed SystemUIServer

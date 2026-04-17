#!/usr/bin/env zsh

source "${HOME}/.local/share/chezmoi/scripts/macos-flags.zsh"

# Mail - disable animations
defaults write com.apple.mail DisableReplyAnimations -bool true             # legacy kept
defaults write com.apple.mail DisableSendAnimations -bool true              # legacy kept

# Mail - copy addresses without display names
defaults write com.apple.mail AddressesIncludeNameOnPasteboard -bool false  # ok

mark_restart_needed Mail

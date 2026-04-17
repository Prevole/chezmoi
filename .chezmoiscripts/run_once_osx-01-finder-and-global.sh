#!/usr/bin/env zsh

source "${HOME}/.local/share/chezmoi/scripts/macos-flags.zsh"

# Finder - preferred view style: list view
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"   # ok

# Finder - show hidden files
defaults write com.apple.finder AppleShowAllFiles -bool true          # legacy kept

# Finder - search current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"   # legacy kept

# Global - jump to clicked spot in scroll bar
defaults write NSGlobalDomain AppleScrollerPagingBehavior -bool true  # ok

# Spotlight - hide menu bar item
# defaults write com.apple.Spotlight MenuItemHidden -int 1            # avoid
# legacy -> use UI: System Settings > Menu Bar > Spotlight

mark_restart_needed Finder

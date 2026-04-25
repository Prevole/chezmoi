#!/usr/bin/env zsh

# Software Update - enable automatic checks
defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true  # ok

# Software Update - download in background
defaults write com.apple.SoftwareUpdate AutomaticDownload -int 1          # ok

# Software Update - install critical updates
defaults write com.apple.SoftwareUpdate CriticalUpdateInstall -int 1      # ok

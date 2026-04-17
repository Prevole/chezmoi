#!/usr/bin/env zsh

# Require password immediately after sleep or screen saver
defaults write com.apple.screensaver askForPassword -int 1       # ok
defaults write com.apple.screensaver askForPasswordDelay -int 0  # ok

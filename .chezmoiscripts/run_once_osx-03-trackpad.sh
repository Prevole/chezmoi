#!/usr/bin/env zsh

# Trackpad - tap to click
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -int 1                      # legacy kept
defaults write com.apple.AppleMultitouchTrackpad Clicking -int 1                                       # legacy kept
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1                                       # legacy kept

# Trackpad - bottom-right secondary click
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadCornerSecondaryClick -int 2  # legacy kept
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true        # legacy kept
defaults write NSGlobalDomain com.apple.trackpad.trackpadCornerClickBehavior -int 1                    # legacy kept
defaults write NSGlobalDomain com.apple.trackpad.enableSecondaryClick -bool true                       # legacy kept

# Modern equivalent:
# use UI: System Settings > Trackpad > Point & Click

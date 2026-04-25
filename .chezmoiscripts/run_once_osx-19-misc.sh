#!/usr/bin/env zsh

# Photos - don't open automatically when a device is plugged in
defaults -currentHost write com.apple.ImageCapture disableHotPlug -bool true  # ok

# Time Machine - don't offer new disks for backup
defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true  # ok

# Locale - metric units
defaults write NSGlobalDomain AppleMeasurementUnits -string "Centimeters"  # ok
defaults write NSGlobalDomain AppleMetricUnits -bool true                   # ok

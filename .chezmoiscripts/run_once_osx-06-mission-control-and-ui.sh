#!/usr/bin/env zsh

# Windows - prefer tabs when opening documents
defaults write NSGlobalDomain AppleWindowTabbingMode -string "always"                # ok

# Stage Manager / desktop reveal behavior
defaults write com.apple.WindowManager EnableStandardClickToShowDesktop -bool false  # legacy kept

# Save panel - expanded by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true          # ok
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true         # ok

# Print panel - expanded by default
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true              # ok
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true             # ok

# Save to disk by default instead of iCloud
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false           # ok

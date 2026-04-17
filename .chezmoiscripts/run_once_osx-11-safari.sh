#!/usr/bin/env zsh

source "${HOME}/.local/share/chezmoi/scripts/macos-flags.zsh"

# Safari - hide favorites bar
defaults write com.apple.Safari ShowFavoritesBar -bool false                                                          # ok

# Safari - internal debug menu
defaults write com.apple.Safari IncludeInternalDebugMenu -bool true                                                   # legacy kept

# Safari - Develop menu and Web Inspector
defaults write com.apple.Safari IncludeDevelopMenu -bool true                                                         # ok
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true                                  # legacy kept
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true  # legacy kept

# Web Inspector in web views
defaults write NSGlobalDomain WebKitDeveloperExtras -bool true                                                        # legacy kept

# Safari - privacy / search
defaults write com.apple.Safari UniversalSearchEnabled -bool false                                                    # legacy kept
defaults write com.apple.Safari SuppressSearchSuggestions -bool true                                                  # ok

# Safari - show full URL
defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool true                                              # ok

# Safari - Do Not Track
defaults write com.apple.Safari SendDoNotTrackHTTPHeader -bool true                                                   # legacy kept

# Safari - auto-update extensions
defaults write com.apple.Safari InstallExtensionUpdatesAutomatically -bool true                                       # ok

mark_restart_needed Safari

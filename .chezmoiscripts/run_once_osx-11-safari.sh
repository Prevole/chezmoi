#!/usr/bin/env zsh

source "${HOME}/.local/share/chezmoi/scripts/macos-flags.zsh"

# Safari preferences are sandboxed since macOS Sonoma and may not be writable.
# All defaults write commands below use || true to avoid interrupting the setup.

# Safari - hide favorites bar
defaults write com.apple.Safari ShowFavoritesBar -bool false || true                                                          # ok

# Safari - internal debug menu
defaults write com.apple.Safari IncludeInternalDebugMenu -bool true || true                                                   # legacy kept

# Safari - Develop menu and Web Inspector
defaults write com.apple.Safari IncludeDevelopMenu -bool true || true                                                         # ok
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true || true                                  # legacy kept
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true || true  # legacy kept

# Web Inspector in web views
defaults write NSGlobalDomain WebKitDeveloperExtras -bool true || true                                                        # legacy kept

# Safari - privacy / search
defaults write com.apple.Safari UniversalSearchEnabled -bool false || true                                                    # legacy kept
defaults write com.apple.Safari SuppressSearchSuggestions -bool true || true                                                  # ok

# Safari - show full URL
defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool true || true                                              # ok

# Safari - auto-update extensions
defaults write com.apple.Safari InstallExtensionUpdatesAutomatically -bool true || true                                       # ok

mark_restart_needed Safari

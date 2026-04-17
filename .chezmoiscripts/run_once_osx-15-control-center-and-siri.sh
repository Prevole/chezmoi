#!/usr/bin/env zsh

source "${HOME}/.local/share/chezmoi/scripts/macos-flags.zsh"

# Menu Bar / Control Center - Bluetooth
defaults write com.apple.controlcenter "NSStatusItem Visible Bluetooth" -bool true    # legacy kept

# Menu Bar / Control Center - Screen Mirroring
defaults write com.apple.airplay showInMenuBarIfPresent -bool true                    # legacy kept

# Menu Bar / Control Center - Sound
defaults write com.apple.controlcenter "NSStatusItem Visible Sound" -bool true        # legacy kept

# Menu Bar / Control Center - Now Playing
defaults write com.apple.controlcenter "NSStatusItem Visible NowPlaying" -bool false  # legacy kept
# note: prefer com.apple.controlcenter here over com.apple.airplay

# Siri - hide menu bar icon
defaults write com.apple.Siri SiriPrefStashedStatusMenuVisible -bool false            # legacy kept

# Siri - disable voice trigger
defaults write com.apple.Siri VoiceTriggerUserEnabled -bool false                     # legacy kept

# Modern equivalent:
# use UI: System Settings > Menu Bar
# use UI: System Settings > Siri & Spotlight

mark_restart_needed SystemUIServer

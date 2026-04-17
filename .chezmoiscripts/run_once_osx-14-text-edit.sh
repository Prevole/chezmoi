#!/usr/bin/env zsh

source "${HOME}/.local/share/chezmoi/scripts/macos-flags.zsh"

# TextEdit - use plain text for new documents
defaults write com.apple.TextEdit RichText -int 0                   # ok

# TextEdit - UTF-8 read/write
defaults write com.apple.TextEdit PlainTextEncoding -int 4          # ok
defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4  # ok

mark_restart_needed TextEdit

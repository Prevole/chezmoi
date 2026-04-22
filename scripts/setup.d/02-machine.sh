# =============================================================================
# macOS machine configuration
#
# Renames the machine using its serial number (MAC<serial>), disables the
# startup sound, and installs Rosetta 2.
#
# Requires sudo; authenticates once and reuses the ticket for all calls.
# =============================================================================

COMPUTER_NAME_SUFFIX=$(ioreg -c IOPlatformExpertDevice -d 2 | awk -F \" '/IOPlatformSerialNumber/{print $(NF-1)}')
COMPUTER_NAME="MAC$COMPUTER_NAME_SUFFIX"
CURRENT_NAME=$(scutil --get ComputerName 2>/dev/null || echo "")

log_info ""
log_info "Current computer name : $CURRENT_NAME"
log_info "Proposed computer name: $COMPUTER_NAME"
log_info ""

if [[ "$CURRENT_NAME" != "$COMPUTER_NAME" ]]; then
  read -r -p "Rename this machine to '$COMPUTER_NAME'? [y/N] " rename_answer

  if [[ "${rename_answer}" =~ ^[Yy]$ ]]; then
    log_info "Renaming machine..."

    # Authenticate once; the sudo ticket is reused for subsequent calls.
    sudo -v

    sudo scutil --set ComputerName "$COMPUTER_NAME"
    sudo scutil --set LocalHostName "$COMPUTER_NAME"
    sudo scutil --set HostName "$COMPUTER_NAME"
    sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "$COMPUTER_NAME"

    log_success "Machine renamed to $COMPUTER_NAME."
  else
    log_skip "Machine rename skipped. Keeping current name: $CURRENT_NAME."
  fi
else
  log_skip "Machine name is already correct. Skip."
fi

CURRENT_AUDIO_VOLUME=$(nvram SystemAudioVolume 2>/dev/null | awk '{print $2}' || true)
if [[ "$CURRENT_AUDIO_VOLUME" == "%80" || "$CURRENT_AUDIO_VOLUME" == " " ]]; then
  log_skip "Startup sound already disabled. Skip."
else
  log_info "Disabling startup sound..."

  sudo nvram SystemAudioVolume="%80"

  log_success "Startup sound disabled."
fi

if [ ! -f /usr/libexec/rosetta/oahd ]; then
  log_info "Installing Rosetta 2..."

  softwareupdate --install-rosetta --agree-to-license || true

  log_success "Rosetta 2 installed."
else
  log_skip "Rosetta 2 already installed. Skip."
fi

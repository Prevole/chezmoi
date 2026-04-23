# =============================================================================
# SSH key cleanup
#
# Removes the SSH private keys that were temporarily extracted from 1Password
# to disk by 04-ssh-keys.sh. After chezmoi apply, the 1Password SSH agent
# serves all keys — no private key files are needed on disk.
#
# Only the temporary private key files created by 04-ssh-keys.sh are removed:
#   - ~/.ssh/id_ed25519          (primary key)
#   - ~/.ssh/<personal-key-slug> (personal key, work profile only)
# =============================================================================

TEMP_KEYS=()

[ -f ~/.ssh/id_ed25519 ] && TEMP_KEYS+=(~/.ssh/id_ed25519)

# Personal key: any key matching <personal-key-slug> derived from PERSONAL_KEY_TITLE
if [[ -n "$PERSONAL_KEY_TITLE" ]]; then
  PERSONAL_KEY_SLUG=$(echo "$PERSONAL_KEY_TITLE" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
  PERSONAL_KEY_FILE=~/.ssh/${PERSONAL_KEY_SLUG}

  [ -f "$PERSONAL_KEY_FILE" ] && TEMP_KEYS+=("$PERSONAL_KEY_FILE")
fi

if [[ ${#TEMP_KEYS[@]} -eq 0 ]]; then
  log_skip "No temporary SSH key files found. Skip."
else
  log_info "The following temporary SSH key files were extracted from 1Password"
  log_info "during setup and are no longer needed. The 1Password SSH agent"
  log_info "serves all keys going forward."
  log_info ""

  for key in "${TEMP_KEYS[@]}"; do
    log_info "  $key"
  done

  log_info ""
  read -r -p "Delete temporary SSH key files? [y/N] " delete_answer

  if [[ "${delete_answer}" =~ ^[Yy]$ ]]; then
    for key in "${TEMP_KEYS[@]}"; do
      rm -f "$key"
    done

    log_success "Temporary SSH key files deleted. 1Password SSH agent is now the sole key provider."
  else
    log_skip "Temporary SSH key files kept."
  fi
fi

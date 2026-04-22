# =============================================================================
# SSH key generation and GitHub registration
#
# Generates an ED25519 SSH key for the machine, displays the public key,
# copies it to the clipboard, and pauses to allow adding it to GitHub.
# If the account uses EMU/SSO, the key must also be authorized per org.
# Optionally generates a second key for a personal GitHub account, named
# <username>-<hostname>-ed25519.
#
# Exports:
#   SSH_KEY_TITLE — item title used to import the primary key in 1Password
#                   e.g. "<username> - <hostname> - ED25519"
# =============================================================================

if [ ! -d ~/.ssh ]; then
  log_info "Creating SSH directory..."

  mkdir ~/.ssh

  log_success "SSH directory created."
else
  log_skip "SSH directory already exists. Skip."
fi

SSH_KEY_TITLE="$(whoami) - $(hostname) - ED25519"

if [ ! -f ~/.ssh/id_ed25519 ]; then
  log_info "Generating SSH key..."

  ssh-keygen -t ed25519 -C "$(whoami)@$(hostname)" -f ~/.ssh/id_ed25519 -N ""

  cat ~/.ssh/id_ed25519.pub | pbcopy

  log_box "SSH public key generated" \
    "Use this title in GitHub: $SSH_KEY_TITLE" \
    "" \
    "$(cat ~/.ssh/id_ed25519.pub)"

  log_info "The public key has been copied to your clipboard."
  log_info ""
  log_warn "IMPORTANT: If your GitHub account is managed by your organization (EMU/SSO),"
  log_warn "you must also authorize this SSH key for SSO on each required organization:"
  log_warn "  GitHub -> Settings -> SSH and GPG keys -> find this key -> Configure SSO"
  log_info ""

  read -r -p "Press Enter after adding the SSH key to GitHub..."

  log_success "SSH key added to GitHub."
else
  log_skip "SSH key already exists. Skip."
fi

if [ ! -d ~/Documents/repositories ]; then
  log_info "Creating repositories directory..."

  mkdir -p ~/Documents/repositories

  log_success "Repositories directory created."
else
  log_skip "Repositories directory already exists. Skip."
fi

# Check if a personal SSH key already exists (pattern: *-<hostname>-ed25519)
EXISTING_PERSONAL_KEY=$(find ~/.ssh -maxdepth 1 -name "*-$(hostname)-ed25519" ! -name "id_ed25519" 2>/dev/null | head -1)

if [[ -n "$EXISTING_PERSONAL_KEY" ]]; then
  log_skip "Personal SSH key already exists (${EXISTING_PERSONAL_KEY}). Skip."
else
  log_info ""
  log_info "If you have a personal GitHub account, you can generate a separate SSH key for it."
  read -r -p "Generate a personal GitHub SSH key? [y/N] " personal_key_answer

  if [[ "${personal_key_answer}" =~ ^[Yy]$ ]]; then
    read -r -p "Enter your personal GitHub username: " personal_github_user

    PERSONAL_KEY_FILE=~/.ssh/${personal_github_user}-$(hostname)-ed25519
    PERSONAL_KEY_TITLE="${personal_github_user} - $(hostname) - ED25519"

    log_info "Generating personal SSH key..."

    ssh-keygen -t ed25519 -C "${personal_github_user}@$(hostname)" -f "$PERSONAL_KEY_FILE" -N ""

    cat "$PERSONAL_KEY_FILE.pub" | pbcopy

    log_box "Personal SSH public key generated" \
      "Use this title in GitHub: $PERSONAL_KEY_TITLE" \
      "" \
      "$(cat "$PERSONAL_KEY_FILE.pub")"

    log_info "The public key has been copied to your clipboard."
    log_info ""

    read -r -p "Press Enter after adding the personal SSH key to GitHub..."
    log_success "Personal SSH key added to GitHub."
  fi
fi
fi

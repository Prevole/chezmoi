# =============================================================================
# SSH key generation via 1Password and GitHub registration
#
# Generates ED25519 SSH keys directly in the 1Password vault named after the
# hostname (created by 03-1password.sh). Keys are never written to disk here —
# they live exclusively in 1Password and are served by the SSH agent.
#
# A temporary extraction to disk happens later in 08-dotfiles.sh to allow
# chezmoi to clone the dotfiles repo via SSH, then cleaned up in 98-ssh-cleanup.sh.
#
# Requires:
#   PROFILE  — set by 00-profile.sh
#   HOSTNAME — set by 03-1password.sh
#
# Exports:
#   SSH_KEY_TITLE      — primary key item title in 1Password
#   PERSONAL_KEY_TITLE — personal key item title (work profile only, if created)
# =============================================================================

# Re-authenticate if the op session expired since 03-1password.sh
op whoami &>/dev/null || eval "$(op signin)"

if [ ! -d ~/.ssh ]; then
  log_info "Creating SSH directory..."
  mkdir -p ~/.ssh
  chmod 700 ~/.ssh
  log_success "SSH directory created."
else
  log_skip "SSH directory already exists. Skip."
fi

# ---------------------------------------------------------------------------
# Primary SSH key
# ---------------------------------------------------------------------------

SSH_KEY_TITLE="$(whoami) - ${HOSTNAME} - ED25519"

if op item get "$SSH_KEY_TITLE" --vault "$HOSTNAME" &>/dev/null; then
  log_skip "Primary SSH key '$SSH_KEY_TITLE' already exists in 1Password. Skip."
else
  log_info "Generating primary SSH key in 1Password..."

  op item create \
    --category "SSH Key" \
    --title "$SSH_KEY_TITLE" \
    --vault "$HOSTNAME" \
    --ssh-generate-key Ed25519

  log_success "Primary SSH key created in 1Password."
fi

log_box "Add your primary SSH key to GitHub" \
  "Key title : $SSH_KEY_TITLE" \
  "" \
  "Open the item in 1Password, then use the autofill integration to add the" \
  "key directly to GitHub — no copy/paste needed." \
  "" \
  "IMPORTANT: In the 1Password item, set the Hosts field to:" \
  "  ssh://git@github.com" \
  "" \
  "Docs — Add key to GitHub (autofill):" \
  "  https://developer.1password.com/docs/ssh/public-key-autofill#github" \
  "" \
  "Docs — Register key for commit signing:" \
  "  https://developer.1password.com/docs/ssh/git-commit-signing#step-2-register-your-public-key"

open "https://github.com/settings/keys"

log_warn "If your GitHub account is managed by your organization (EMU/SSO),"
log_warn "authorize this key for SSO: GitHub > Settings > SSH keys > Configure SSO"

read -r -p "Press Enter after adding the primary SSH key to GitHub..."
log_success "Primary SSH key added to GitHub."

# ---------------------------------------------------------------------------
# Personal SSH key (work profile only)
# ---------------------------------------------------------------------------

PERSONAL_KEY_TITLE=""

if [[ "$PROFILE" == "work" ]]; then
  # Look for an existing personal key in the vault (any SSH key that is not the primary)
  EXISTING_PERSONAL=$(op item list --vault "$HOSTNAME" --categories "SSH Key" --format json 2>/dev/null \
    | ruby -rjson -e "puts JSON.parse(STDIN.read).map{|i| i['title']}.reject{|t| t == '$SSH_KEY_TITLE'}.first.to_s")

  if [[ -n "$EXISTING_PERSONAL" ]]; then
    log_skip "Personal SSH key '$EXISTING_PERSONAL' already exists in 1Password. Skip."
    PERSONAL_KEY_TITLE="$EXISTING_PERSONAL"
  else
    log_info ""
    log_info "Work profile: a separate SSH key is needed for a personal GitHub account."
    read -r -p "Generate a personal GitHub SSH key? [y/N] " personal_key_answer

    if [[ "${personal_key_answer}" =~ ^[Yy]$ ]]; then
      read -r -p "Enter your personal GitHub username: " personal_github_user

      PERSONAL_KEY_TITLE="${personal_github_user} - ${HOSTNAME} - ED25519"

      log_info "Generating personal SSH key in 1Password..."

      op item create \
        --category "SSH Key" \
        --title "$PERSONAL_KEY_TITLE" \
        --vault "$HOSTNAME" \
        --ssh-generate-key Ed25519

      log_success "Personal SSH key created in 1Password."

      log_box "Add your personal SSH key to GitHub" \
        "Key title : $PERSONAL_KEY_TITLE" \
        "" \
        "Open the item in 1Password, then use the autofill integration to add the" \
        "key directly to GitHub — no copy/paste needed." \
        "" \
        "IMPORTANT: In the 1Password item, set the Hosts field to:" \
        "  ssh://git@github-perso" \
        "" \
        "Docs — Add key to GitHub (autofill):" \
        "  https://developer.1password.com/docs/ssh/public-key-autofill#github" \
        "" \
        "Docs — Register key for commit signing:" \
        "  https://developer.1password.com/docs/ssh/git-commit-signing#step-2-register-your-public-key"

      open "https://github.com/settings/keys"

      read -r -p "Press Enter after adding the personal SSH key to your personal GitHub account..."
      log_success "Personal SSH key added to GitHub."
    fi
  fi
fi

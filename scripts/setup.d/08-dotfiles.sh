# =============================================================================
# chezmoi init and dotfiles application
#
# Extracts SSH keys temporarily from 1Password to disk so that git/chezmoi
# can clone the dotfiles repository via SSH. Keys are removed after apply
# by 98-ssh-cleanup.sh — the 1Password SSH agent takes over from there.
#
# Resolves the dotfiles repository URL from the git remote of the directory
# containing mac-setup.sh. Converts HTTPS to SSH if needed. On a work profile,
# offers to rewrite github.com to github-perso for personal repos.
#
# chezmoi.yaml is already written by 05-chezmoi.sh so promptChoiceOnce will
# not prompt again. User directories are created by 07-directories.sh.
# =============================================================================

# Re-authenticate if the op session expired
op whoami &>/dev/null || eval "$(op signin)"

# ---------------------------------------------------------------------------
# Extract SSH keys temporarily from 1Password to allow git clone via SSH.
# Primary key → ~/.ssh/id_ed25519 (default key picked up by SSH automatically)
# Personal key → ~/.ssh/<title-slug> (named key, loaded via ssh-add)
# ---------------------------------------------------------------------------

log_info "Extracting SSH keys from 1Password for git clone..."

op read "op://${HOSTNAME}/${SSH_KEY_TITLE}/private key" > ~/.ssh/id_ed25519
chmod 600 ~/.ssh/id_ed25519

log_success "Primary SSH key extracted temporarily."

if [[ -n "$PERSONAL_KEY_TITLE" ]]; then
  PERSONAL_KEY_SLUG=$(echo "$PERSONAL_KEY_TITLE" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
  PERSONAL_KEY_FILE=~/.ssh/${PERSONAL_KEY_SLUG}

  op read "op://${HOSTNAME}/${PERSONAL_KEY_TITLE}/private key" > "$PERSONAL_KEY_FILE"
  chmod 600 "$PERSONAL_KEY_FILE"
  ssh-add "$PERSONAL_KEY_FILE" 2>/dev/null || true

  log_success "Personal SSH key extracted temporarily."
fi

# ---------------------------------------------------------------------------
# Resolve dotfiles repository URL
# ---------------------------------------------------------------------------

if [ ! -d ~/.local/share/chezmoi ]; then
  log_info "Initializing chezmoi with your dotfiles repository..."

  REPO_DIR="$(dirname "${BASH_SOURCE[0]}")/../.."
  REMOTE_URL=$(git -C "$REPO_DIR" remote get-url origin)
  CURRENT_BRANCH=$(git -C "$REPO_DIR" branch --show-current)

  # Convert HTTPS to SSH if needed — SSH URLs are used as-is
  if [[ "$REMOTE_URL" == https://* ]]; then
    # https://github.com/user/repo.git -> git@github.com:user/repo.git
    SSH_URL=$(echo "$REMOTE_URL" | sed 's|https://\([^/]*\)/|\1:|' | sed 's|^|git@|')
  else
    SSH_URL="$REMOTE_URL"
  fi

  # On work profile, a personal GitHub repo must use the github-perso SSH alias
  # so that the SSH agent selects the personal key instead of the work key.
  if [[ "$PROFILE" == "work" && "$SSH_URL" == *"git@github.com"* ]]; then
    log_info ""
    log_info "This dotfiles repository is hosted on github.com."
    log_info "On a work profile, personal GitHub repos should use the 'github-perso' SSH alias."
    read -r -p "Is this a personal GitHub repository? [y/N] " perso_answer

    if [[ "${perso_answer}" =~ ^[Yy]$ ]]; then
      SSH_URL="${SSH_URL/git@github.com/git@github-perso}"
    fi
  fi

  log_info "Repository : $SSH_URL"
  log_info "Branch     : $CURRENT_BRANCH"

  # Pass --branch only when not on the default branch
  BRANCH_ARG=""
  if [[ "$CURRENT_BRANCH" != "main" && "$CURRENT_BRANCH" != "master" && -n "$CURRENT_BRANCH" ]]; then
    BRANCH_ARG="--branch $CURRENT_BRANCH"
  fi

  # shellcheck disable=SC2086
  chezmoi init --apply $BRANCH_ARG "$SSH_URL"

  log_success "Dotfiles applied."
else
  log_skip "Chezmoi already initialized. Skip."
fi

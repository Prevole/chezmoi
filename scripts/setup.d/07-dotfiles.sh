# =============================================================================
# chezmoi init and dotfiles application
#
# Resolves the dotfiles repository URL from the git remote of the directory
# containing mac-setup.sh. If the URL is HTTPS, converts it to SSH. If it is
# already an SSH URL, uses it as-is.
#
# On a work profile, if the SSH URL points to github.com, offers to rewrite
# it to github-perso to match the SSH alias used for personal repositories.
#
# chezmoi.yaml is already written by 04-chezmoi.sh so promptChoiceOnce will
# not prompt again.
# =============================================================================

if [ ! -d ~/.local/share/chezmoi ]; then
  log_info "Initializing chezmoi with your dotfiles repository..."

  REPO_DIR="$(dirname "${BASH_SOURCE[0]}")/../.."
  REMOTE_URL=$(git -C "$REPO_DIR" remote get-url origin)

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

  log_info "Repository: $SSH_URL"

  chezmoi init --apply "$SSH_URL"

  log_success "Dotfiles applied."
else
  log_skip "Chezmoi already initialized. Skip."
fi

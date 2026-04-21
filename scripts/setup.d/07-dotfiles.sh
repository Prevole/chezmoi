# =============================================================================
# chezmoi init and dotfiles application
#
# Resolves the dotfiles repository URL from the git remote of the directory
# containing mac-setup.sh, converts it from HTTPS to SSH, and passes it to
# chezmoi init --apply. chezmoi.yaml is already written by 04-chezmoi.sh so
# promptChoiceOnce will not prompt again.
# =============================================================================

if [ ! -d ~/.local/share/chezmoi ]; then
  log_info "Initializing chezmoi with your dotfiles repository..."

  REPO_DIR="$(dirname "${BASH_SOURCE[0]}")/../.."
  HTTPS_URL=$(git -C "$REPO_DIR" remote get-url origin)

  # Convert https://github.com/user/repo.git -> git@github.com:user/repo.git
  SSH_URL="${HTTPS_URL/https:\/\//git@}"
  SSH_URL="${SSH_URL/\//\:}"

  log_info "Repository: $SSH_URL"

  chezmoi init --apply "$SSH_URL"

  log_success "Dotfiles applied."
else
  log_skip "Chezmoi already initialized. Skip."
fi

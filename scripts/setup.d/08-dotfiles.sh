# =============================================================================
# chezmoi init and dotfiles application
#
# Initializes chezmoi and applies the dotfiles. SSH keys are already extracted
# temporarily to disk by 04-ssh-keys.sh and will be cleaned up by 98-ssh-cleanup.sh.
#
# Resolves the dotfiles repository URL from the git remote of the directory
# containing mac-setup.sh. Converts HTTPS to SSH if needed. On a work profile,
# offers to rewrite github.com to github-perso for personal repos.
#
# Restarts 1Password after chezmoi apply so the SSH agent picks up agent.toml
# (deployed by chezmoi). chezmoi.yaml is already written by 00-profile.sh so
# promptChoiceOnce will not prompt again. User directories are created by
# 07-directories.sh.
# =============================================================================

# Re-authenticate if the op session expired
op whoami &>/dev/null || eval "$(op signin)"

# ---------------------------------------------------------------------------
# Resolve dotfiles repository URL
# ---------------------------------------------------------------------------

if [ ! -d ~/.local/share/chezmoi ]; then
  log_info "Initializing chezmoi with your dotfiles repository..."

  REPO_DIR="$(dirname "${BASH_SOURCE[0]}")/../.."
  REMOTE_URL=$(git -C "$REPO_DIR" remote get-url origin)
  CURRENT_BRANCH=$(git -C "$REPO_DIR" branch --show-current)

  # Normalize to SCP-style SSH URL (git@host:user/repo.git) — the format
  # shown by GitHub UI and the one chezmoi passes directly to git.
  # Handles both HTTPS and SCP inputs.
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
      SSH_URL="${SSH_URL/github.com/github-perso}"
    fi
  fi

  log_info "Repository : $SSH_URL"
  log_info "Branch     : $CURRENT_BRANCH"

  # Pass --branch only when not on the default branch
  BRANCH_ARG=""
  if [[ "$CURRENT_BRANCH" != "main" && "$CURRENT_BRANCH" != "master" && -n "$CURRENT_BRANCH" ]]; then
    BRANCH_ARG="--branch $CURRENT_BRANCH"
  fi

  # Select the SSH identity to use based on the target URL:
  #   - github-perso → personal key extracted by 04-ssh-keys.sh
  #   - anything else → primary key (~/.ssh/id_ed25519)
  # IdentitiesOnly=yes disables the 1Password agent so it cannot interfere.
  if [[ "$SSH_URL" == *"github-perso"* && -n "$PERSONAL_KEY_TITLE" ]]; then
    PERSONAL_KEY_SLUG=$(echo "$PERSONAL_KEY_TITLE" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
    SSH_IDENTITY=~/.ssh/${PERSONAL_KEY_SLUG}
  else
    SSH_IDENTITY=~/.ssh/id_ed25519
  fi

  # shellcheck disable=SC2086
  GIT_SSH_COMMAND="ssh -i $SSH_IDENTITY -o IdentitiesOnly=yes" \
    chezmoi init --apply $BRANCH_ARG "$SSH_URL"

  log_success "Dotfiles applied."
else
  log_skip "Chezmoi already initialized. Skip."
fi

log_info "Restarting 1Password so the SSH agent picks up agent.toml..."
killall "1Password" 2>/dev/null || true
sleep 2
open -a "1Password"
read -r -p "Press Enter once 1Password is back up and the SSH agent shows as running..."

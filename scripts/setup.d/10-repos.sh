# =============================================================================
# Git repositories cloning
#
# Clones all repositories declared in the 1Password "Git Repositories - <profile>"
# note that are not already present on the filesystem.
#
# Calls the repos_clone.rb script from the lp oh-my-zsh plugin directly,
# bypassing the shell plugin (not yet sourced at this point in setup).
# Uses the system Ruby (/usr/bin/ruby) to avoid depending on mise being
# activated in the current shell.
#
# Requires:
#   PROFILE                      — set by 00-profile.sh
#   op                           — signed in (03-1password.sh)
#   ~/.config/gitrepos/config.yaml — deployed by chezmoi (08-dotfiles.sh)
# =============================================================================

REPOS_CLONE_SCRIPT="${HOME}/.oh-my-zsh/custom/plugins/lp/repos_clone.rb"
GITREPOS_CONFIG="${HOME}/.config/gitrepos/config.yaml"

if [[ ! -f "$GITREPOS_CONFIG" ]]; then
  log_skip "~/.config/gitrepos/config.yaml not found. Skip repository cloning."
  log_skip "Run 'repos_clone' manually after setup."
elif [[ ! -f "$REPOS_CLONE_SCRIPT" ]]; then
  log_skip "repos_clone.rb not found. Skip repository cloning."
  log_skip "Run 'repos_clone' manually after setup."
else
  log_info "Cloning Git repositories from 1Password..."

  op whoami &>/dev/null || eval "$(op signin)"

  /usr/bin/ruby "$REPOS_CLONE_SCRIPT"

  log_success "Git repositories cloned."
fi

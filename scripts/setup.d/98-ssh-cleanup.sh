# =============================================================================
# SSH key cleanup
#
# Once chezmoi has been applied and the SSH agent is fully operational,
# the local SSH private key files are no longer needed — keys are served
# by the 1Password SSH agent. This script offers to remove them.
#
# Must run after 07-dotfiles.sh to ensure chezmoi has applied the SSH config
# and the agent is ready before the local key files are deleted.
# =============================================================================

SSH_KEYS=$(find ~/.ssh -maxdepth 1 -type f ! -name "*.pub" ! -name "config" ! -name "known_hosts" ! -name "authorized_keys")

if [ -n "$SSH_KEYS" ]; then
  log_info ""
  log_info "The following SSH keys are now stored in 1Password and served by the SSH agent."
  log_info "The local key files are no longer needed."
  log_info ""
  log_info "$SSH_KEYS"
  log_info ""

  read -r -p "Delete all local SSH private keys? [y/N] " delete_answer

  if [[ "${delete_answer}" =~ ^[Yy]$ ]]; then
    find ~/.ssh -maxdepth 1 -type f ! -name "*.pub" ! -name "config" ! -name "known_hosts" ! -name "authorized_keys" -delete
    find ~/.ssh -maxdepth 1 -name "*.pub" -delete

    log_success "Local SSH key files deleted."
  else
    log_skip "Local SSH key files kept."
  fi
else
  log_skip "No local SSH private key files found. Skip."
fi

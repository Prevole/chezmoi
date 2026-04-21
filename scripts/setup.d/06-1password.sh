# =============================================================================
# 1Password setup, vault creation, and SSH key import
#
# Bootstraps 1Password for SSH agent use:
#   - Opens 1Password for login and Developer Settings configuration.
#   - Creates a vault named after the hostname via the op CLI.
#     The agent.toml points to this vault — it must exist before chezmoi runs.
#   - Copies agent.toml from the chezmoi source so 1Password picks it up
#     before chezmoi runs (chicken-and-egg: agent.toml is normally deployed
#     by chezmoi, but chezmoi needs the SSH agent to clone the repo).
#   - Opens ~/.ssh for manual SSH key import (CLI import is not supported).
#   - Restarts 1Password so the agent picks up the imported key.
#
# Exports:
#   HOSTNAME      — machine hostname
#   SSH_KEY_TITLE — item title used to locate the key in the vault
#                   e.g. "<username> - <hostname> - <algorithm>"
# =============================================================================

AGENT_TOML_SRC="$(dirname "${BASH_SOURCE[0]}")/../../dot_config/private_1Password/private_ssh/private_agent.toml.tmpl"
AGENT_TOML_DST="${HOME}/.config/1Password/ssh/agent.toml"

open -a "1Password"
read -r -p "Please log in to 1Password and complete the Developer Settings setup before proceeding. Press Enter to continue after you're done..."

HOSTNAME=$(hostname)
SSH_KEY_TITLE="$(whoami) - ${HOSTNAME} - ED25519"

log_info "Signing in to 1Password CLI..."

eval "$(op signin)"

log_success "Signed in to 1Password CLI."

if ! op vault get "$HOSTNAME" &>/dev/null; then
  log_info "Creating 1Password vault '$HOSTNAME'..."

  op vault create "$HOSTNAME"

  log_success "Vault '$HOSTNAME' created."
else
  log_skip "1Password vault '$HOSTNAME' already exists. Skip."
fi

log_box "Manual step: import your SSH keys into 1Password" \
  "Main key : $SSH_KEY_TITLE" \
  "Vault    : $HOSTNAME" \
  "Path     : 1Password > Developer Settings > SSH Keys > Add SSH Key"

open ~/.ssh
read -r -p "Press Enter once the SSH keys are imported into the '$HOSTNAME' vault..."

log_info "Restarting 1Password to ensure the SSH key is fully loaded by the agent..."
killall "1Password" 2>/dev/null || true

sleep 2

if [ ! -f "$AGENT_TOML_DST" ]; then
  log_info "Copying 1Password SSH agent config (one-shot bootstrap)..."

  mkdir -p "$(dirname "$AGENT_TOML_DST")"
  chezmoi execute-template < "$AGENT_TOML_SRC" > "$AGENT_TOML_DST"

  log_success "1Password SSH agent config copied."
else
  log_skip "1Password SSH agent config already exists. Skip."
fi

open -a "1Password"
read -r -p "Press Enter once 1Password is back up and the SSH agent shows as running..."

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
fi

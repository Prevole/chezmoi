# =============================================================================
# 1Password setup and vault creation
#
# Bootstraps 1Password:
#   - Installs 1Password and the op CLI if not already present.
#   - Opens 1Password for login and Developer Settings configuration.
#   - Signs in to the op CLI.
#   - Creates a vault named after the hostname via the op CLI.
#     The agent.toml points to this vault — it must exist before chezmoi runs.
#
# agent.toml is deployed by chezmoi (08-dotfiles.sh), after which 1Password
# is restarted so the SSH agent picks up the configuration.
#
# Sets:
#   HOSTNAME — machine hostname (reused by 04-ssh-keys.sh and 08-dotfiles.sh)
# =============================================================================

if ! brew list --cask 1password &>/dev/null; then
  log_info "Installing 1Password..."
  brew install --cask 1password
  log_success "1Password installed."
  sleep 3
else
  log_skip "1Password already installed. Skip."
fi

if ! brew list 1password-cli &>/dev/null; then
  log_info "Installing 1Password CLI..."
  brew install 1password-cli
  log_success "1Password CLI installed."
else
  log_skip "1Password CLI already installed. Skip."
fi

open -a "1Password"
read -r -p "Please log in to 1Password and complete the Developer Settings setup before proceeding. Press Enter to continue after you're done..."

HOSTNAME=$(hostname)

log_info "Signing in to 1Password CLI..."

op whoami &>/dev/null || eval "$(op signin)"

log_success "Signed in to 1Password CLI."

if ! op vault get "$HOSTNAME" &>/dev/null; then
  log_info "Creating 1Password vault '$HOSTNAME'..."

  op vault create "$HOSTNAME"

  log_success "Vault '$HOSTNAME' created."
else
  log_skip "1Password vault '$HOSTNAME' already exists. Skip."
fi

# =============================================================================
# 1Password setup, vault creation, and SSH agent bootstrap
#
# Bootstraps 1Password for SSH agent use:
#   - Opens 1Password for login and Developer Settings configuration.
#   - Signs in to the op CLI (re-authenticates if session expired).
#   - Creates a vault named after the hostname via the op CLI.
#     The agent.toml points to this vault — it must exist before chezmoi runs.
#   - Copies agent.toml from the chezmoi source so 1Password picks it up
#     before chezmoi runs (chicken-and-egg: agent.toml is normally deployed
#     by chezmoi, but chezmoi needs the SSH agent to clone the repo).
#   - Restarts 1Password so the agent picks up the configuration.
#
# Exports:
#   HOSTNAME — machine hostname (reused by 04-ssh-keys.sh and 07-dotfiles.sh)
# =============================================================================

AGENT_TOML_SRC="$(dirname "${BASH_SOURCE[0]}")/../../dot_config/private_1Password/private_ssh/private_agent.toml.tmpl"
AGENT_TOML_DST="${HOME}/.config/1Password/ssh/agent.toml"

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

if [ ! -f "$AGENT_TOML_DST" ]; then
  log_info "Copying 1Password SSH agent config (one-shot bootstrap)..."

  mkdir -p "$(dirname "$AGENT_TOML_DST")"
  CHEZMOI_SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
  chezmoi execute-template --source "$CHEZMOI_SOURCE" < "$AGENT_TOML_SRC" > "$AGENT_TOML_DST"

  log_success "1Password SSH agent config copied."
else
  log_skip "1Password SSH agent config already exists. Skip."
fi

log_info "Restarting 1Password to ensure the SSH agent config is loaded..."
killall "1Password" 2>/dev/null || true

sleep 2

open -a "1Password"
read -r -p "Press Enter once 1Password is back up and the SSH agent shows as running..."

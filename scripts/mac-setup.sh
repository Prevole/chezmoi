#!/usr/bin/env bash
set -euo pipefail

if ! command -v brew &> /dev/null; then
  echo "Homebrew not found. Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo "Homebrew already installed. Skip."
fi

if ! command -v brew &> /dev/null; then
  echo "Homebrew not in PATH. Setting up brew environment..."
  eval "$(/opt/homebrew/bin/brew shellenv)"
  echo "Homebrew environment ready."
fi

brew upgrade

COMPUTER_NAME_SUFFIX=$(ioreg -c IOPlatformExpertDevice -d 2 | awk -F \" '/IOPlatformSerialNumber/{print $(NF-1)}')
COMPUTER_NAME="MAC$COMPUTER_NAME_SUFFIX"
CURRENT_NAME=$(scutil --get ComputerName 2>/dev/null || echo "")

echo ""
echo "Current computer name : $CURRENT_NAME"
echo "Proposed computer name: $COMPUTER_NAME"
echo ""

if [[ "$CURRENT_NAME" == "$COMPUTER_NAME" ]]; then
  echo "Machine name is already correct. Skip."
else
  read -r -p "Rename this machine to '$COMPUTER_NAME'? [y/N] " rename_answer

  if [[ "${rename_answer}" =~ ^[Yy]$ ]]; then
    echo "Renaming machine..."

    # Authenticate once; the sudo ticket is reused for subsequent calls.
    sudo -v

    sudo scutil --set ComputerName "$COMPUTER_NAME"
    sudo scutil --set LocalHostName "$COMPUTER_NAME"
    sudo scutil --set HostName "$COMPUTER_NAME"
    sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "$COMPUTER_NAME"

    echo "Machine renamed to $COMPUTER_NAME."
  else
    echo "Machine rename skipped. Keeping current name: $CURRENT_NAME."
  fi
fi

CURRENT_AUDIO_VOLUME=$(nvram SystemAudioVolume 2>/dev/null | awk '{print $2}' || echo "unset")
if [[ "$CURRENT_AUDIO_VOLUME" == " " ]]; then
  echo "Startup sound already disabled. Skip."
else
  echo "Disabling startup sound..."
  sudo nvram SystemAudioVolume=" "
fi

if [ -f /usr/libexec/rosetta/oahd ]; then
  echo "Rosetta 2 already installed. Skip."
else
  echo "Installing Rosetta 2..."
  softwareupdate --install-rosetta --agree-to-license
fi

if [ ! -d ~/.ssh ]; then
  echo "SSH directory not found. Creating SSH directory..."
  mkdir ~/.ssh
else
  echo "SSH directory already exists. Skip."
fi

if [ ! -f ~/.ssh/id_ed25519 ]; then
  echo "SSH key not found. Generating SSH key..."
  ssh-keygen -t ed25519 -C "$(whoami)@$(hostname)" -f ~/.ssh/id_ed25519 -N ""

  SSH_KEY_TITLE="$(whoami) - $(hostname) - ED25519"

  echo ""
  echo "================================================================"
  echo " SSH public key generated"
  echo " Use this title in GitHub: $SSH_KEY_TITLE"
  echo "================================================================"
  cat ~/.ssh/id_ed25519.pub
  echo "================================================================"
  echo ""
  cat ~/.ssh/id_ed25519.pub | pbcopy
  echo "The public key has been copied to your clipboard."
  echo ""
  echo "IMPORTANT: If your GitHub account is managed by your organization (EMU/SSO),"
  echo "you must also authorize this SSH key for SSO on each required organization:"
  echo "  GitHub -> Settings -> SSH and GPG keys -> find this key -> Configure SSO"
  echo ""

  read -r -p "Press Enter after adding the SSH key to GitHub..."
else
  echo "SSH key already exists. Skip."
fi

if [ ! -d ~/Documents/repositories ]; then
  echo "Repositories directory not found. Creating repositories directory..."
  mkdir -p ~/Documents/repositories
else
  echo "Repositories directory already exists. Skip."
fi

# Install chezmoi early so we can use execute-template to render the Brewfile
# before running brew bundle. Same chicken-and-egg problem as 1Password.
if ! command -v chezmoi &> /dev/null; then
  echo "Installing chezmoi (required to render Brewfile template)..."
  brew install chezmoi
else
  echo "chezmoi already installed. Skip."
fi

echo ""
read -r -p "Setup type [personal/work]: " SETUP_TYPE

while [[ "$SETUP_TYPE" != "personal" && "$SETUP_TYPE" != "work" ]]; do
  echo "Invalid choice. Please enter 'personal' or 'work'."
  read -r -p "Setup type [personal/work]: " SETUP_TYPE
done

echo "Setup type: $SETUP_TYPE"

FULL_SETUP=false
read -r -p "Full setup (install all tools for this setup type)? [y/N]: " full_setup_answer
if [[ "${full_setup_answer}" =~ ^[Yy]$ ]]; then
  FULL_SETUP=true
fi
echo "Full setup: $FULL_SETUP"

# Write the chezmoi config early so that execute-template picks up setupType
# and fullSetup when rendering the Brewfile (and the agent.toml) below.
mkdir -p ~/.config/chezmoi
cat > ~/.config/chezmoi/chezmoi.yaml <<EOF
data:
  setupType: "${SETUP_TYPE}"
  fullSetup: ${FULL_SETUP}
EOF

BREWFILE_TMPL="$(dirname "$0")/../dot_homebrew/Brewfile.tmpl"
BREWFILE_RENDERED="/tmp/Brewfile"

echo "Rendering Brewfile for setup type '$SETUP_TYPE' (fullSetup: $FULL_SETUP)..."
chezmoi execute-template < "$BREWFILE_TMPL" > "$BREWFILE_RENDERED"

echo "Installing applications and tools from Brewfile..."
brew bundle install --file="$BREWFILE_RENDERED"

# ---------------------------------------------------------------------------
# One-shot bootstrap: copy the 1Password SSH agent config before chezmoi runs.
# This is necessary to break the chicken-and-egg problem: chezmoi needs the
# 1Password SSH agent to authenticate via SSH, but the agent config is normally
# deployed by chezmoi itself. Copying it manually here ensures 1Password picks
# it up as soon as it is set up, before chezmoi apply runs.
# This file will be overwritten and properly managed by chezmoi afterwards.
# ---------------------------------------------------------------------------
AGENT_TOML_SRC="$(dirname "$0")/../dot_config/private_1Password/private_ssh/private_agent.toml.tmpl"
AGENT_TOML_DST="${HOME}/.config/1Password/ssh/agent.toml"

if [ ! -f "$AGENT_TOML_DST" ]; then
  echo "Copying 1Password SSH agent config (one-shot bootstrap)..."
  mkdir -p "$(dirname "$AGENT_TOML_DST")"
  chezmoi execute-template < "$AGENT_TOML_SRC" > "$AGENT_TOML_DST"
else
  echo "1Password SSH agent config already exists. Skip."
fi

open -a "1Password"
read -r -p "Please log in to 1Password and complete the setup before proceeding. Press Enter to continue after you're done..."

echo "Restarting 1Password to ensure SSH agent and keys are properly loaded..."
killall "1Password" 2>/dev/null || true

sleep 2

open -a "1Password"
read -r -p "Press Enter once 1Password is back up and the SSH agent shows as running..."

# ---------------------------------------------------------------------------
# Create the machine vault in 1Password and import the SSH key.
# This is required so that the 1Password SSH agent can serve the key to Git
# and GitHub via SSH. The agent.toml config points to a vault named after the
# machine hostname — if this vault or the key entry does not exist, chezmoi
# init (and all subsequent SSH operations) will fail.
# The vault and key entry are created automatically below via the op CLI.
# If this step fails, refer to the README for the manual fallback procedure.
# ---------------------------------------------------------------------------
HOSTNAME=$(hostname)
SSH_KEY_TITLE="$(whoami) - ${HOSTNAME} - ED25519"

echo "Signing in to 1Password CLI..."
eval "$(op signin)"

if ! op vault get "$HOSTNAME" &>/dev/null; then
  echo "Creating 1Password vault '$HOSTNAME'..."
  op vault create "$HOSTNAME"
else
  echo "1Password vault '$HOSTNAME' already exists. Skip."
fi

if ! op item get "$SSH_KEY_TITLE" --vault "$HOSTNAME" &>/dev/null; then
  echo "Importing SSH key into 1Password vault '$HOSTNAME'..."

  SSH_PUBLIC_KEY=$(cat ~/.ssh/id_ed25519.pub)
  SSH_FINGERPRINT=$(ssh-keygen -lf ~/.ssh/id_ed25519.pub | awk '{print $2}')
  SSH_KEY_TYPE=$(ssh-keygen -lf ~/.ssh/id_ed25519.pub | awk '{print $NF}' | tr -d '()')

  SSH_KEY_TEMPLATE_SRC="$(dirname "$0")/1password-ssh-key-template.json"
  SSH_KEY_TEMPLATE_FILE=$(mktemp /tmp/ssh-key-template.XXXXXX.json)
  jq \
    --rawfile key ~/.ssh/id_ed25519 \
    --arg title "$SSH_KEY_TITLE" \
    --arg pubkey "$SSH_PUBLIC_KEY" \
    --arg fingerprint "$SSH_FINGERPRINT" \
    --arg keytype "$SSH_KEY_TYPE" \
    '
      .title = $title |
      .fields[1].value = $key |
      .fields[2].value = $pubkey |
      .fields[3].value = $fingerprint |
      .fields[4].value = $keytype
    ' \
    "$SSH_KEY_TEMPLATE_SRC" > "$SSH_KEY_TEMPLATE_FILE"

  op item create --vault "$HOSTNAME" --template "$SSH_KEY_TEMPLATE_FILE"
  rm -f "$SSH_KEY_TEMPLATE_FILE"

  echo "SSH key imported as '$SSH_KEY_TITLE'."
else
  echo "SSH key entry '$SSH_KEY_TITLE' already exists in vault '$HOSTNAME'. Skip."
fi

if [ ! -d ~/.local/share/chezmoi ]; then
  echo "Chezmoi not found. Initializing chezmoi with your dotfiles repository..."
  chezmoi init --apply 'git@github.com:REDACTED_REDACTED/env.git'
else
  echo "Chezmoi already initialized. Skip."
fi

if [ -f ~/.ssh/id_ed25519 ]; then
  echo ""
  echo "The SSH key ~/.ssh/id_ed25519 is now stored in 1Password and served by the SSH agent."
  echo "The local key file is no longer needed."

  read -r -p "Delete ~/.ssh/id_ed25519 and ~/.ssh/id_ed25519.pub? [y/N] " delete_answer

  if [[ "${delete_answer}" =~ ^[Yy]$ ]]; then
    rm -f ~/.ssh/id_ed25519 ~/.ssh/id_ed25519.pub
    echo "Local SSH key files deleted."
  else
    echo "Local SSH key files kept."
  fi
fi

echo ""
read -r -p "Setup complete. Restart now? [y/N] " answer
if [[ "${answer}" =~ ^[Yy]$ ]]; then
  echo "Restarting..."
  sudo shutdown -r now
else
  echo "Restart skipped. Please restart your machine manually to apply all changes."
fi

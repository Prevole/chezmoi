# =============================================================================
# Homebrew installation and upgrade
# =============================================================================

# Source brew shellenv if brew is not in PATH but already installed
if ! command -v brew &> /dev/null; then
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

if ! command -v brew &> /dev/null; then
  log_info "Installing Homebrew..."

  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"

  log_success "Homebrew installed."
else
  log_skip "Homebrew already installed. Skip."
fi

brew upgrade

# =============================================================================
# Homebrew installation and upgrade
# =============================================================================

if ! command -v brew &> /dev/null; then
  log_info "Homebrew not found. Installing Homebrew..."

  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  log_success "Homebrew installed."
else
  log_skip "Homebrew already installed. Skip."
fi

if ! command -v brew &> /dev/null; then
  log_info "Homebrew not in PATH. Setting up brew environment..."

  eval "$(/opt/homebrew/bin/brew shellenv)"

  log_success "Homebrew environment ready."
fi

brew upgrade

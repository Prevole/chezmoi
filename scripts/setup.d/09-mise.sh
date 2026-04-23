# =============================================================================
# mise — install global runtimes
#
# Runs 'mise install' to install all tools declared in ~/.config/mise/config.toml,
# which is deployed by chezmoi in 08-dotfiles.sh.
#
# Requires:
#   mise — installed via Homebrew in 06-apps.sh
#   ~/.config/mise/config.toml — deployed by chezmoi in 08-dotfiles.sh
# =============================================================================

if ! command -v mise &>/dev/null; then
  log_warn "mise not found in PATH. Skipping runtime installation."
  log_warn "Run 'mise install' manually after setup."
else
  log_info "Installing global runtimes via mise..."

  mise install

  log_success "mise runtimes installed."
fi

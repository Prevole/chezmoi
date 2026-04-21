# =============================================================================
# Applications installation
#
# Installs all applications and CLI tools from the rendered Brewfile.
#
# Depends on:
#   BREWFILE_RENDERED
# =============================================================================

log_info "Installing applications and tools from Brewfile..."

brew bundle install --file="$BREWFILE_RENDERED"

log_success "Applications installed."

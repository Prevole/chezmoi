# =============================================================================
# Create user directories
#
# Creates standard directories expected by the rest of the setup and by
# chezmoi-managed tools (e.g. repos_clone). Runs before dotfiles are applied
# so the directories are always present regardless of the machine state.
# =============================================================================

if [ ! -d ~/Documents/repositories ]; then
  log_info "Creating repositories directory..."
  mkdir -p ~/Documents/repositories
  log_success "Repositories directory created."
else
  log_skip "Repositories directory already exists. Skip."
fi

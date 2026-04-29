# =============================================================================
# Create user directories
#
# Creates standard directories expected by the rest of the setup and by
# chezmoi-managed tools (e.g. repos_clone). Runs before dotfiles are applied
# so the directories are always present regardless of the machine state.
# =============================================================================

# Read git_root from chezmoi config (written by 00-profile.sh).
# Falls back to the default if the config or key is missing.
_chezmoi_config="${HOME}/.config/chezmoi/chezmoi.yaml"
_git_root=$(awk '/^data:/{in_data=1} in_data && /git_root:/{print $2; exit}' "$_chezmoi_config" 2>/dev/null)
_git_root="${_git_root:-~/Documents/repositories}"
# Expand ~ manually (bash does not expand ~ in variable assignments)
_git_root="${_git_root/#\~/$HOME}"

if [ ! -d "$_git_root" ]; then
  log_info "Creating repositories directory ($_git_root)..."
  mkdir -p "$_git_root"
  log_success "Repositories directory created."
else
  log_skip "Repositories directory already exists ($_git_root). Skip."
fi

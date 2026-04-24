# =============================================================================
# chezmoi installation and Brewfile rendering
#
# Installs chezmoi early to render the Brewfile template before brew bundle
# runs (chicken-and-egg: the Brewfile is a template requiring chezmoi).
# Profile is already set by 00-profile.sh.
#
# Exports:
#   BREWFILE_RENDERED — path to the rendered Brewfile: /tmp/Brewfile
# =============================================================================

if ! command -v chezmoi &> /dev/null; then
  log_info "Installing chezmoi..."

  brew install chezmoi

  log_success "chezmoi installed."
else
  log_skip "chezmoi already installed. Skip."
fi

BREWFILE_TMPL="$(dirname "${BASH_SOURCE[0]}")/../../dot_homebrew/Brewfile.tmpl"
BREWFILE_RENDERED="/tmp/Brewfile"
CHEZMOI_SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

log_info "Rendering Brewfile for profile '$PROFILE'..."

# Detect VM early (same logic as .chezmoi.yaml.tmpl) so that is_vm is
# available to the Brewfile template before chezmoi init runs.
HW_MODEL=$(sysctl -n hw.model 2>/dev/null || echo "")
IS_VM=false
case "$HW_MODEL" in
  VMware*|VirtualMac*|Parallels*) IS_VM=true ;;
esac

chezmoi execute-template \
  --source "$CHEZMOI_SOURCE" \
  --data "{\"profile\":\"$PROFILE\",\"is_vm\":$IS_VM}" \
  < "$BREWFILE_TMPL" > "$BREWFILE_RENDERED"

log_success "Brewfile rendered."

# =============================================================================
# chezmoi installation and configuration
#
# Installs chezmoi early to render the Brewfile template before brew bundle
# runs (chicken-and-egg: the Brewfile is a template requiring chezmoi).
# Prompts for setupType and fullSetup, writes chezmoi.yaml, and renders
# the Brewfile template.
#
# Exports:
#   SETUP_TYPE        — profile selected by the user: "personal" or "work"
#   FULL_SETUP        — whether all tools are installed: true or false
#   BREWFILE_RENDERED — path to the rendered Brewfile: /tmp/Brewfile
# =============================================================================

if ! command -v chezmoi &> /dev/null; then
  log_info "Installing chezmoi..."

  brew install chezmoi

  log_success "chezmoi installed."
else
  log_skip "chezmoi already installed. Skip."
fi

log_info ""
read -r -p "Setup type [personal/work]: " SETUP_TYPE

while [[ "$SETUP_TYPE" != "personal" && "$SETUP_TYPE" != "work" ]]; do
  log_warn "Invalid choice. Please enter 'personal' or 'work'."
  read -r -p "Setup type [personal/work]: " SETUP_TYPE
done

log_success "Setup type: $SETUP_TYPE"

FULL_SETUP=false
read -r -p "Full setup (install all tools for this setup type)? [y/N]: " full_setup_answer
if [[ "${full_setup_answer}" =~ ^[Yy]$ ]]; then
  FULL_SETUP=true
fi
log_success "Full setup: $FULL_SETUP"

mkdir -p ~/.config/chezmoi
cat > ~/.config/chezmoi/chezmoi.yaml <<EOF
data:
  setupType: "${SETUP_TYPE}"
  fullSetup: ${FULL_SETUP}
EOF

BREWFILE_TMPL="$(dirname "${BASH_SOURCE[0]}")/../../dot_homebrew/Brewfile.tmpl"
BREWFILE_RENDERED="/tmp/Brewfile"

log_info "Rendering Brewfile for setup type '$SETUP_TYPE' (fullSetup: $FULL_SETUP)..."

chezmoi execute-template < "$BREWFILE_TMPL" > "$BREWFILE_RENDERED"

log_success "Brewfile rendered."

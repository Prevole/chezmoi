# =============================================================================
# chezmoi installation and configuration
#
# Installs chezmoi early to render the Brewfile template before brew bundle
# runs (chicken-and-egg: the Brewfile is a template requiring chezmoi).
# Prompts for profile and fullSetup, writes chezmoi.yaml, and renders
# the Brewfile template.
#
# Exports:
#   PROFILE           — profile selected by the user: "work", "lp" or "sp"
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
read -r -p "Profile [work/lp/sp]: " PROFILE

while [[ "$PROFILE" != "work" && "$PROFILE" != "lp" && "$PROFILE" != "sp" ]]; do
  log_warn "Invalid choice. Please enter 'work', 'lp' or 'sp'."
  read -r -p "Profile [work/lp/sp]: " PROFILE
done

log_success "Profile: $PROFILE"

FULL_SETUP=false
read -r -p "Full setup (install all tools for this profile)? [y/N]: " full_setup_answer
if [[ "${full_setup_answer}" =~ ^[Yy]$ ]]; then
  FULL_SETUP=true
fi
log_success "Full setup: $FULL_SETUP"

mkdir -p ~/.config/chezmoi
cat > ~/.config/chezmoi/chezmoi.yaml <<EOF
git:
  autoCommit: true
  autoPush: true

data:
  profile: "${PROFILE}"
  fullSetup: ${FULL_SETUP}
EOF

BREWFILE_TMPL="$(dirname "${BASH_SOURCE[0]}")/../../dot_homebrew/Brewfile.tmpl"
BREWFILE_RENDERED="/tmp/Brewfile"

log_info "Rendering Brewfile for profile '$PROFILE' (fullSetup: $FULL_SETUP)..."

chezmoi execute-template < "$BREWFILE_TMPL" > "$BREWFILE_RENDERED"

log_success "Brewfile rendered."

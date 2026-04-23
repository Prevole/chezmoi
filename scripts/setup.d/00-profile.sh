# =============================================================================
# Profile selection
#
# Prompts the user for the machine profile and writes it to chezmoi.yaml.
# Runs first so that all subsequent scripts can rely on $PROFILE being set.
#
# If chezmoi.yaml already exists with a profile (re-run), the value is read
# from there and the prompt is skipped.
#
# Exports:
#   PROFILE — profile selected by the user: "work", "lp" or "sp"
# =============================================================================

if [[ -f ~/.config/chezmoi/chezmoi.yaml ]]; then
  PROFILE=$(grep 'profile:' ~/.config/chezmoi/chezmoi.yaml | awk '{print $2}' | tr -d '"')
  log_skip "Profile already set to '$PROFILE'. Skip."
else
  read -r -p "Profile [work/lp/sp]: " PROFILE

  while [[ "$PROFILE" != "work" && "$PROFILE" != "lp" && "$PROFILE" != "sp" ]]; do
    log_warn "Invalid choice. Please enter 'work', 'lp' or 'sp'."
    read -r -p "Profile [work/lp/sp]: " PROFILE
  done

  log_success "Profile: $PROFILE"

  mkdir -p ~/.config/chezmoi
  cat > ~/.config/chezmoi/chezmoi.yaml <<EOF
git:
  autoCommit: true
  autoPush: true

data:
  profile: "${PROFILE}"
EOF
fi

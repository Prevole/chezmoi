# =============================================================================
# Machine restart
#
# Prompts to restart the machine to fully apply all macOS preferences.
# =============================================================================

log_info ""
read -r -p "Setup complete. Restart now? [y/N] " answer

if [[ "${answer}" =~ ^[Yy]$ ]]; then
  log_info "Restarting..."

  sudo shutdown -r now
else
  log_skip "Restart skipped. Please restart your machine manually to apply all changes."
fi

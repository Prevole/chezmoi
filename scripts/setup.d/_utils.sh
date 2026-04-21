# =============================================================================
# Utility functions for setup scripts
#
# Provides colored output helpers. All functions are available to every script
# sourced after this file because they share the same shell environment.
#
# Color variables (GREEN, ORANGE, RED, NC) must be defined by the caller
# (mac-setup.sh) before this file is sourced.
#
# Functions:
#   log_success  <message>  — green: action completed successfully
#   log_skip     <message>  — orange: step skipped (already done)
#   log_warn     <message>  — red: warning or required manual step
#   log_info     <message>  — plain: neutral information or prompt preamble
#   log_box      <title> [<line>...]
#                           — framed block for multi-line instructions
#                             e.g. log_box "SSH key" "$(cat ~/.ssh/id_ed25519.pub)"
# =============================================================================

# Color codes available to all sourced scripts
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No color

log_success() { echo -e "${GREEN}${*}${NC}"; }
log_skip()    { echo -e "${ORANGE}${*}${NC}"; }
log_warn()    { echo -e "${RED}${*}${NC}"; }
log_info()    { echo "${*}"; }

log_box() {
  local title="$1"
  shift
  echo ""
  echo "================================================================"
  echo " ${title}"
  echo "================================================================"
  for line in "${@}"; do
    echo " ${line}"
  done
  echo "================================================================"
  echo ""
}

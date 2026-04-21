#!/usr/bin/env bash

# =============================================================================
# macOS setup orchestrator
#
# Sources each script in setup.d/ in order. Scripts are sourced (not executed)
# so they share the same shell environment and can pass variables to each other.
#
# Each script must be idempotent — it can be sourced multiple times or on an
# already partially configured machine without causing side effects, in the
# same way Ansible playbooks are designed to be run repeatedly.
# =============================================================================

set -euo pipefail

SETUP_D="$(dirname "$0")/setup.d"

# shellcheck source=/dev/null
source "$SETUP_D/_utils.sh"

for script in "$SETUP_D"/[0-9][0-9]-*.sh; do
  echo ""
  echo "===================================================================="
  echo "==> $(basename "$script")"
  echo "===================================================================="

  # shellcheck source=/dev/null
  source "$script"
done

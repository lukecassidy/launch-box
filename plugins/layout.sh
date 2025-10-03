#!/bin/bash

###############################################################################
# Apply window layout via Hammerspoon
#
# Requires Hammerspoon CLI (`hs`) to be installed.
###############################################################################

source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

log INFO "Layout plugin running..."

# check dependencies and skip if missing
if ! is_cmd_installed "lua"; then
    log ERROR "Skipping layout: lua not installed"
    exit_or_return 0
fi
if ! is_app_installed "Hammerspoon"; then
    log ERROR "Skipping layout: Hammerspoon not installed"
    exit_or_return 0
fi


log INFO "Applying window layout via Hammerspoon..."
if /opt/homebrew/bin/hs -c "applyWorkspace()"; then
    log INFO "Requested Hammerspoon to apply workspace layout."
else
    log ERROR "Failed to apply Hammerspoon workspace layout."
    exit_or_return 1
fi

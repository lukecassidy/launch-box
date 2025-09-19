#!/bin/bash

###############################################################################
# Apply window layout via Hammerspoon
###############################################################################

source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

log INFO "Layout plugin running..."

# check dependencies and skip if missing
if ! is_cmd_installed "lua"; then
    log ERROR "Skipping layout: lua not installed"
    return 0
fi
if ! is_app_installed "Hammerspoon"; then
    log ERROR "Skipping layout: Hammerspoon not installed"
    return 0
fi


log INFO "Applying window layout via Hammerspoon..."
hs -c "applyWorkspace()"

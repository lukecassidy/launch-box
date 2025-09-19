#!/bin/bash

###############################################################################
# Apply window layout via Hammerspoon
###############################################################################

source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
log INFO "Applying window layout via Hammerspoon..."
hs -c "applyWorkspace()"

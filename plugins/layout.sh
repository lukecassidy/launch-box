#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
echo "Applying window layout via Hammerspoon..."
hs -c "applyWorkspace()"

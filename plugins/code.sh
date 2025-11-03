#!/bin/bash

###############################################################################
# Merge all Visual Studio Code windows into a single window
###############################################################################

source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
log INFO "Merging all Visual Studio Code 'mac' windows..."

code_cmd="click menu item \"Merge All Windows\" of menu \"Window\" of menu bar 1"

for proc_name in "Code" "Electron"; do
    wait_for_process "$proc_name" 5 1 && break
done

# Merge all windows via menu
gui_run_applescript <<EOF
tell application "System Events"
    tell process "$proc_name"
        set frontmost to true
        delay 0.3
        $code_cmd
    end tell
end tell
EOF

log INFO "Requested VS Code to merge all windows."

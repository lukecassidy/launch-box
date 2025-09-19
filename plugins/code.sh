#!/bin/bash

###############################################################################
# Merge all Visual Studio Code 'mac' windows into a single window
###############################################################################

source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
log INFO "Merging all Visual Studio Code 'mac' windows..."

# Merge all Visual Studio Code windows
osascript <<'EOF'
tell application "System Events"
    tell process "Code"
        set frontmost to true
        try
            click menu item "Merge All Windows" of menu "Window" of menu bar 1
        on error
            display notification "Couldn't merge windows. " with title "Visual Studio Code"
        end try
    end tell
end tell
EOF

log INFO "Requested VS Code to merge all windows."

#!/bin/bash

###############################################################################
# Merge all Visual Studio Code 'mac' windows into a single window
###############################################################################

source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
log INFO "Merging all Visual Studio Code 'mac' windows..."

# Merge all Visual Studio Code windows
osascript <<'EOF'
tell application "System Events"
    -- Wait briefly if VS Code hasn't finished launching yet
    set waited to 0
    repeat until exists (process "Code") or (waited > 10)
        delay 0.5
        set waited to waited + 0.5
    end repeat

    if exists (process "Code") then
        tell process "Code"
            set frontmost to true
            delay 0.3
            try
                click menu item "Merge All Windows" of menu "Window" of menu bar 1
            on error
                display notification "Couldn't merge windows." with title "Visual Studio Code"
            end try
        end tell
    end if
end tell
EOF

log INFO "Requested VS Code to merge all windows."
#!/bin/bash

###############################################################################
# Merge all Visual Studio Code 'mac' windows into a single window
###############################################################################

source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
log INFO "Merging all Visual Studio Code 'mac' windows..."

# Merge all Visual Studio Code windows
osascript <<'EOF'
tell application "System Events"
    -- The process name could be either "Code" or "Electron"
    set procName to missing value
    repeat 10 times
        try
            if exists process "Code" then
                set procName to process "Code"
                exit repeat
            else if exists process "Electron" then
                set procName to process "Electron"
                exit repeat
            end if
        end try
        delay 0.5
    end repeat

    if procName is not missing value then
        tell procName
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
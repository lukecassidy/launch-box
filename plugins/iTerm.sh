#!/bin/bash

###############################################################################
# iTerm config script to create panes and run commands
###############################################################################

source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
log INFO 'iTerm configuration script running...'

# Create two horizontal panes and run test commands
osascript <<'EOF'
tell application "iTerm"
    activate
    tell current window
        set newTab to (create tab with default profile)
        tell current session of newTab
            write text "echo 'Pane 1'"
            split horizontally with default profile
        end tell
        delay 0.5
        tell session 2 of newTab
            write text "echo 'Pane 2'"
        end tell
    end tell
end tell
EOF
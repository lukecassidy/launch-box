#!/bin/bash

###############################################################################
# iTerm config script to create panes and run commands
###############################################################################

source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
log INFO 'iTerm configuration script running...'

# check dependencies and skip if missing
if ! is_cmd_installed "osascript"; then
    log ERROR "Skipping iTerm configuration: osascript not installed"
    return 0
fi
if ! is_app_installed "iTerm"; then
    log ERROR "Skipping iTerm configuration: iTerm not installed"
    return 0
fi


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
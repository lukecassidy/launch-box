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


# Create a three-pane workspace (top plus two lower panes) and run starter commands
if ! osascript <<'EOF'; then
    tell application "iTerm"
        activate

        set targetWindow to missing value
        set workingTab to missing value

        if (count of windows) = 0 then
            set targetWindow to (create window with default profile)
            set workingTab to current tab of targetWindow
        else
            set targetWindow to current window
            if targetWindow is missing value then
                set targetWindow to (create window with default profile)
                set workingTab to current tab of targetWindow
            else
                tell targetWindow
                    set workingTab to (create tab with default profile)
                end tell
            end if
        end if

        tell targetWindow
            if workingTab is missing value then
                set workingTab to current tab
            end if

            set pane1 to current session of workingTab
            tell pane1
                write text "echo 'Pane 1'"
                set pane2 to (split horizontally with default profile)
            end tell

            tell pane2
                write text "echo 'Pane 2'"
                set pane3 to (split vertically with default profile)
                tell pane3
                    write text "echo 'Pane 3'"
                end tell
            end tell
        end tell
    end tell
EOF

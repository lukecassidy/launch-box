#!/bin/bash

###############################################################################
# iTerm config script to create panes and run commands
###############################################################################

source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

log INFO 'iTerm configuration script running...'

# check dependencies and skip if missing
if ! is_cmd_installed "osascript"; then
    log ERROR "Skipping iTerm configuration: osascript not installed"
    exit_or_return 0
fi

# check if iTerm is installed
if ! is_app_installed "iTerm"; then
    log ERROR "Skipping iTerm configuration: iTerm not installed"
    exit_or_return 0
fi

# check for jq
if ! is_cmd_installed "jq"; then
    log ERROR "Skipping iTerm configuration: jq not installed"
    exit_or_return 0
fi

# check for config path
if [[ -z "${LAUNCH_BOX_CONFIG:-}" ]]; then
    log ERROR "Skipping iTerm configuration: config file path not provided"
    exit_or_return 0
fi

# get pane commands from config
pane_commands=$(jq -r '.plugins.iTerm.panes[]?' "$LAUNCH_BOX_CONFIG" 2>/dev/null)
if [[ -z "$pane_commands" ]]; then
    log WARNING "No iTerm pane commands defined in config, skipping"
    exit_or_return 0
fi

# read commands into array
IFS=$'\n' read -d '' -r -a commands <<< "$pane_commands" || true

# export pane commands for AppleScript
export PANE1_COMMAND="${commands[0]:-clear}"
export PANE2_COMMAND="${commands[1]:-clear}"
export PANE3_COMMAND="${commands[2]:-clear}"

# Create a three-pane workspace (top plus two lower panes) and run starter commands
if ! osascript <<'EOF'; then
    set pane1Command to system attribute "PANE1_COMMAND"
    set pane2Command to system attribute "PANE2_COMMAND"
    set pane3Command to system attribute "PANE3_COMMAND"

    tell application "iTerm"
        activate

        set targetWindow to missing value
        set workingTab to missing value

        try
            set targetWindow to current window
        end try

        if targetWindow is missing value then
            set targetWindow to (create window with default profile)
            set workingTab to current tab of targetWindow
        else
            tell targetWindow
                set workingTab to (create tab with default profile)
            end tell
        end if

        tell targetWindow
            set pane1 to current session of workingTab
            tell pane1
                write text pane1Command
                set pane2 to (split horizontally with default profile)
            end tell

            tell pane2
                write text pane2Command
                set pane3 to (split vertically with default profile)
                tell pane3
                    write text pane3Command
                end tell
            end tell
        end tell
    end tell
EOF
    log ERROR "Failed to configure iTerm panes via AppleScript"
    exit_or_return 1
fi

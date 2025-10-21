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
if ! is_app_installed "iTerm"; then
    log ERROR "Skipping iTerm configuration: iTerm not installed"
    exit_or_return 0
fi


# commands to run in each pane
pane1_command='clear; figlet luke is cool'
pane2_command='clear; echo "K8s: $(kubectl config current-context):$(kubectl config view --minify --output '\''jsonpath={..namespace}'\'' || echo default)"'
pane3_command='clear; echo "AWS: ${$(aws_prompt_info):-default}"'

export PANE1_COMMAND="$pane1_command"
export PANE2_COMMAND="$pane2_command"
export PANE3_COMMAND="$pane3_command"

# Create a three-pane workspace (top plus two lower panes) and run starter commands
if ! run_in_gui_session osascript <<'EOF'; then
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

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

# get iTerm configuration from config
default_profile=$(jq -r '.plugins.iTerm.profile // "Default"' "$LAUNCH_BOX_CONFIG" 2>/dev/null)

# check if panes is an array of strings or objects
pane_type=$(jq -r '.plugins.iTerm.panes[0] | type' "$LAUNCH_BOX_CONFIG" 2>/dev/null)

if [[ "$pane_type" == "object" ]]; then
    # panes with profile per pane
    pane_data=$(jq -r '.plugins.iTerm.panes[] | "\(.command // "clear")|\(.profile // "'"$default_profile"'")"' "$LAUNCH_BOX_CONFIG" 2>/dev/null)
else
    # simple string commands
    pane_data=$(jq -r '.plugins.iTerm.panes[] | . + "|'"$default_profile"'"' "$LAUNCH_BOX_CONFIG" 2>/dev/null)
fi

if [[ -z "$pane_data" ]]; then
    log WARNING "No iTerm pane commands defined in config, skipping"
    exit_or_return 0
fi

# read pane data into arrays
IFS=$'\n' read -d '' -r -a panes <<< "$pane_data" || true

# parse command and profile for each pane
IFS='|' read -r cmd1 prof1 <<< "${panes[0]:-clear|$default_profile}"
IFS='|' read -r cmd2 prof2 <<< "${panes[1]:-clear|$default_profile}"
IFS='|' read -r cmd3 prof3 <<< "${panes[2]:-clear|$default_profile}"

# export pane commands and profiles for AppleScript
export PANE1_COMMAND="${cmd1:-clear}"
export PANE1_PROFILE="${prof1:-$default_profile}"
export PANE2_COMMAND="${cmd2:-clear}"
export PANE2_PROFILE="${prof2:-$default_profile}"
export PANE3_COMMAND="${cmd3:-clear}"
export PANE3_PROFILE="${prof3:-$default_profile}"

# create a three-pane workspace (top plus two lower panes) and run starter commands
if ! osascript <<'EOF'; then
    set pane1Command to system attribute "PANE1_COMMAND"
    set pane1Profile to system attribute "PANE1_PROFILE"
    set pane2Command to system attribute "PANE2_COMMAND"
    set pane2Profile to system attribute "PANE2_PROFILE"
    set pane3Command to system attribute "PANE3_COMMAND"
    set pane3Profile to system attribute "PANE3_PROFILE"

    tell application "iTerm"
        activate

        set targetWindow to missing value
        set workingTab to missing value

        try
            set targetWindow to current window
        end try

        if targetWindow is missing value then
            set targetWindow to (create window with profile pane1Profile)
            set workingTab to current tab of targetWindow
        else
            tell targetWindow
                set workingTab to (create tab with profile pane1Profile)
            end tell
        end if

        tell targetWindow
            set pane1 to current session of workingTab
            tell pane1
                write text pane1Command
                set pane2 to (split horizontally with profile pane2Profile)
            end tell

            tell pane2
                write text pane2Command
                set pane3 to (split vertically with profile pane3Profile)
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

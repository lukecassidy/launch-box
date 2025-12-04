#!/bin/bash

###############################################################################
# iTerm plugin script to dynamically create panes and run commands
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

# get default profile and parse panes (expects object format)
default_profile=$(jq -r '.plugins.iTerm.profile // "Default"' "$LAUNCH_BOX_CONFIG" 2>/dev/null)
pane_data=$(jq -r '.plugins.iTerm.panes[] | "\(.command // "clear")|\(.profile // "'"$default_profile"'")"' "$LAUNCH_BOX_CONFIG" 2>/dev/null)

if [[ -z "$pane_data" ]]; then
    log WARNING "No iTerm pane commands defined in config, skipping"
    exit_or_return 0
fi

# read pane data and export as env variables for AppleScript
IFS=$'\n' read -d '' -r -a panes <<< "$pane_data" || true
pane_count=${#panes[@]}

for i in "${!panes[@]}"; do
    IFS='|' read -r cmd prof <<< "${panes[$i]}"
    export "PANE${i}_COMMAND=${cmd:-clear}"
    export "PANE${i}_PROFILE=${prof:-$default_profile}"
done

# build AppleScript dynamically based on pane count
applescript='
tell application "iTerm"
    activate

    try
        set targetWindow to current window
        tell targetWindow
            set workingTab to (create tab with profile (system attribute "PANE0_PROFILE"))
        end tell
    on error
        set targetWindow to (create window with profile (system attribute "PANE0_PROFILE"))
        set workingTab to current tab of targetWindow
    end try

    tell targetWindow
        set pane0 to current session of workingTab
        tell pane0 to write text (system attribute "PANE0_COMMAND")
'

# generate 2 column grid layout
# - create all rows first (horizontal splits)
# - then add columns (vertical splits)
num_rows=$(( (pane_count + 1) / 2 ))
declare -a row_panes=(0)

# step 1: create rows by splitting pane0 horizontally
for ((row=1; row<num_rows; row++)); do
    applescript+="
        tell pane0 to set pane$((row * 2)) to (split horizontally with profile (system attribute \"PANE$((row * 2))_PROFILE\"))
        tell pane$((row * 2)) to write text (system attribute \"PANE$((row * 2))_COMMAND\")
"
    row_panes+=($((row * 2)))
done

# step 2: split each row vertically to create right column
for ((row=0; row<num_rows; row++)); do
    if (( row * 2 + 1 < pane_count )); then
        applescript+="
        tell pane${row_panes[$row]} to set pane$((row * 2 + 1)) to (split vertically with profile (system attribute \"PANE$((row * 2 + 1))_PROFILE\"))
        tell pane$((row * 2 + 1)) to write text (system attribute \"PANE$((row * 2 + 1))_COMMAND\")
"
    fi
done

applescript+='
    end tell
end tell
'

# run our generated AppleScript
if ! osascript -e "$applescript"; then
    log ERROR "Failed to configure iTerm panes via AppleScript"
    exit_or_return 1
fi

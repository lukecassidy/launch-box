#!/bin/bash

###############################################################################
# iTerm plugin script to dynamically create panes and run commands
###############################################################################

plugin_dir="$(dirname "${BASH_SOURCE[0]}")"
source "$plugin_dir/../lib/common.sh"

# constants
ITERM_APP="iTerm"

# check dependencies and skip if missing
check_dependencies() {
    local -a missing=()
    is_cmd_installed "osascript" || missing+=("osascript")
    is_cmd_installed "jq" || missing+=("jq")
    is_app_installed "$ITERM_APP" || missing+=("$ITERM_APP app")

    if (( ${#missing[@]} )); then
        log ERROR "Skipping iTerm configuration: missing dependencies: ${missing[*]}"
        exit_or_return 0
    fi
}

log INFO "iTerm configuration script running..."

check_dependencies

# ensure config is loaded
# TODO: improve how this is done - then roll out to other plugins
if ! ensure_config_loaded; then
    log ERROR "Skipping iTerm configuration: no config file available"
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

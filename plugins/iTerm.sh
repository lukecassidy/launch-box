#!/bin/bash

###############################################################################
# iTerm plugin script to dynamically create panes and run commands
###############################################################################

plugin_dir="$(dirname "${BASH_SOURCE[0]}")"
source "$plugin_dir/../lib/common.sh"

# constants
ITERM_APP="iTerm"
MAX_PANES=10
GRID_COLUMNS=2

###############################################################################
# Helper Functions
###############################################################################

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

# get default profile from config
get_default_profile() {
    local profile
    profile=$(jq -r '.plugins.iTerm.profile // "Default"' "$LAUNCH_BOX_CONFIG" 2>/dev/null)

    # fallback to "Default" if empty or null
    if [[ -z "$profile" || "$profile" == "null" ]]; then
        echo "Default"
    else
        echo "$profile"
    fi
}

# parse pane configuration from config file
get_pane_data() {
    local default_profile="$1"
    jq -r '.plugins.iTerm.panes[] | "\(.command // "clear")|\(.profile // "'"$default_profile"'")"' "$LAUNCH_BOX_CONFIG" 2>/dev/null
}

# export pane data as env vars for AppleScript
export_pane_vars() {
    local pane_data="$1"
    local default_profile="$2"

    IFS=$'\n' read -d '' -r -a panes <<< "$pane_data" || true

    # set global pane count (intentionally not local - used by caller)
    pane_count=${#panes[@]}

    for i in "${!panes[@]}"; do
        IFS='|' read -r cmd prof <<< "${panes[$i]}"
        export "PANE${i}_COMMAND=${cmd:-clear}"
        export "PANE${i}_PROFILE=${prof:-$default_profile}"
    done
}

# execute AppleScript
apply_applescript() {
    local applescript="$1"
    local output

    if ! output=$(osascript -e "$applescript" 2>&1); then
        log ERROR "Failed to configure iTerm panes via AppleScript"
        [[ -n "$output" ]] && log ERROR "AppleScript output: $output"
        exit_or_return 1
    fi
}

###############################################################################
# Main Execution
###############################################################################

check_dependencies

# ensure config is loaded
# TODO: improve how this is done - then roll out to other plugins
if ! ensure_config_loaded; then
    log ERROR "Skipping iTerm configuration: no config file available"
    exit_or_return 0
fi

log INFO "iTerm configuration script running..."

# get default profile and parse panes
# panes config format: array of objects with 'command' and 'profile' keys
default_profile=$(get_default_profile)
pane_data=$(get_pane_data "$default_profile")

if [[ -z "$pane_data" ]]; then
    log WARNING "No iTerm pane commands defined in config, skipping"
    exit_or_return 0
fi

# export pane data as env vars
export_pane_vars "$pane_data" "$default_profile"

# validate pane count
if (( pane_count > MAX_PANES )); then
    log WARNING "Pane count ($pane_count) exceeds recommended maximum ($MAX_PANES). Continuing anyway."
fi

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

# generate grid layout based on GRID_COLUMNS
# pane numbering: left column is 0,2,4,... right column is 1,3,5,...
# algorithm:
#   1. create all rows first via horizontal splits (creates left column: panes 0,2,4,...)
#   2. split each row vertically to add right column (creates panes 1,3,5,...)
# this approach ensures even vertical distribution before adding columns
num_rows=$(( (pane_count + GRID_COLUMNS - 1) / GRID_COLUMNS ))
declare -a row_panes=(0)  # track left-column pane indices for vertical splits

# step 1: create rows by splitting pane0 horizontally (left column)
for ((row=1; row<num_rows; row++)); do
    applescript+="
        tell pane0 to set pane$((row * GRID_COLUMNS)) to (split horizontally with profile (system attribute \"PANE$((row * GRID_COLUMNS))_PROFILE\"))
        tell pane$((row * GRID_COLUMNS)) to write text (system attribute \"PANE$((row * GRID_COLUMNS))_COMMAND\")
"
    row_panes+=($((row * GRID_COLUMNS)))
done

# step 2: split each row vertically to create right column (odd numbered panes)
for ((row=0; row<num_rows; row++)); do
    if (( row * GRID_COLUMNS + 1 < pane_count )); then
        applescript+="
        tell pane${row_panes[$row]} to set pane$((row * GRID_COLUMNS + 1)) to (split vertically with profile (system attribute \"PANE$((row * GRID_COLUMNS + 1))_PROFILE\"))
        tell pane$((row * GRID_COLUMNS + 1)) to write text (system attribute \"PANE$((row * GRID_COLUMNS + 1))_COMMAND\")
"
    fi
done

applescript+='
    end tell
end tell
'

# execute AppleScript
apply_applescript "$applescript"

log INFO "iTerm configuration applied successfully."
exit_or_return 0
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

# build complete AppleScript for iTerm pane layout
#   - grid layout: left column (0,2,4...), right column (1,3,5...)
#   - creates rows first (horizontal splits), then adds columns (vertical splits)
build_applescript() {
    local pane_count="$1"
    local num_rows=$(( (pane_count + GRID_COLUMNS - 1) / GRID_COLUMNS ))

    cat <<'EOF'
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
EOF

    # horizontal splits: create left column (0,2,4...)
    for ((row=1; row<num_rows; row++)); do
        local pane_idx=$((row * GRID_COLUMNS))
        printf '        tell pane0 to set pane%d to (split horizontally with profile (system attribute "PANE%d_PROFILE"))\n' "$pane_idx" "$pane_idx"
        printf '        tell pane%d to write text (system attribute "PANE%d_COMMAND")\n' "$pane_idx" "$pane_idx"
    done

    # vertical splits: create right column (1,3,5...)
    for ((row=0; row<num_rows; row++)); do
        local left_pane=$((row * GRID_COLUMNS))
        local right_pane=$((left_pane + 1))

        if (( right_pane < pane_count )); then
            printf '        tell pane%d to set pane%d to (split vertically with profile (system attribute "PANE%d_PROFILE"))\n' "$left_pane" "$right_pane" "$right_pane"
            printf '        tell pane%d to write text (system attribute "PANE%d_COMMAND")\n' "$right_pane" "$right_pane"
        fi
    done

    cat <<'EOF'
    end tell
end tell
EOF
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
# TODO: improve how this is done. should be consistent across plugins
if ! ensure_config_loaded; then
    log ERROR "Skipping iTerm configuration: no config file available"
    exit_or_return 0
fi

log INFO "iTerm configuration script running..."

# get default profile and parse panes, [] of command profile keys
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

# build and execute AppleScript
applescript=$(build_applescript "$pane_count")
apply_applescript "$applescript"

log INFO "iTerm configuration applied successfully."
exit_or_return 0
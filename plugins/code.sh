#!/bin/bash

###############################################################################
# Visual Studio Code plugin
#   - Opens configured projects
#   - Merges all windows into a single window
###############################################################################

plugin_dir="$(dirname "${BASH_SOURCE[0]}")"
source "$plugin_dir/../lib/common.sh"

###############################################################################
# Constants
###############################################################################

CODE_APP="Code"
CODE_ALT_APP="Electron"
PROCESS_WAIT_TIMEOUT=5
PROCESS_WAIT_INTERVAL=1
MERGE_DELAY=0.3

###############################################################################
# Helper Functions
###############################################################################

# check dependencies and skip if missing
check_dependencies() {
    local -a missing=()
    local code_cli
    code_cli=$(echo "$CODE_APP" | tr '[:upper:]' '[:lower:]')  # lowercase to "code"

    is_cmd_installed "$code_cli" || missing+=("code CLI")
    is_cmd_installed "jq" || missing+=("jq")
    is_cmd_installed "osascript" || missing+=("osascript")

    if (( ${#missing[@]} )); then
        log ERROR "Skipping VS Code configuration: missing dependencies: ${missing[*]}"
        exit_or_return 0
    fi
}

# open projects from config
open_projects() {
    local projects
    projects=$(jq -r '.plugins.code.projects[]?' "$LAUNCH_BOX_CONFIG" 2>/dev/null)

    if [[ -z "$projects" ]]; then
        log INFO "No VS Code projects configured"
        return 0
    fi

    log INFO "Opening VS Code projects..."
    while IFS= read -r project; do
        [[ -z "$project" ]] && continue

        # expand tilde to home directory
        project="${project/#\~/$HOME}"

        if [[ ! -d "$project" ]]; then
            log WARNING "Project directory does not exist: $project"
            continue
        fi

        # remember first valid project (intentionally global)
        if [[ -z "$FIRST_PROJECT" ]]; then
            FIRST_PROJECT="$project"
        fi

        log INFO "Opening project: $project"
        code "$project" </dev/null
    done <<< "$projects"
}

# merge all windows into a single window
merge_windows() {
    local proc_name
    local code_cmd="click menu item \"Merge All Windows\" of menu \"Window\" of menu bar 1"

    log INFO "Merging all VS Code windows..."

    # wait for VS Code process to be running
    for proc_name in "$CODE_APP" "$CODE_ALT_APP"; do
        wait_for_process "$proc_name" "$PROCESS_WAIT_TIMEOUT" "$PROCESS_WAIT_INTERVAL" && break
    done || {
        log ERROR "Visual Studio Code process not found."
        exit_or_return 1
    }

    # merge all windows via menu
    if ! osascript <<EOF
tell application "System Events"
    tell process "$proc_name"
        set frontmost to true
        delay $MERGE_DELAY
        $code_cmd
    end tell
end tell
EOF
    then
        log ERROR "Failed to request VS Code to merge all windows."
        exit_or_return 1
    fi

    log INFO "Requested VS Code to merge all windows."
}

###############################################################################
# Main Execution
###############################################################################

check_dependencies

# ensure config is loaded
if ! ensure_config_loaded; then
    log WARNING "No config file available, skipping VS Code configuration"
    exit_or_return 0
fi

# open projects if configured
open_projects

# merge all vscode windows
merge_windows

# focus on first project if available
if [[ -n "$FIRST_PROJECT" ]]; then
    log INFO "Focusing on first project..."
    code "$FIRST_PROJECT" </dev/null
fi

log INFO "VS Code configuration completed."
exit_or_return 0

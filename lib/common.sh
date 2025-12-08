#!/bin/bash

# Prevent repeated sourcing
[[ -n "${__COMMON_SH_LOADED:-}" ]] && return
__COMMON_SH_LOADED=1

# Fallback for non-login shells
HOME="${HOME:-$(eval echo ~$(whoami))}"
PATH="$PATH:/usr/local/bin:/usr/local/sbin:/opt/homebrew/bin"

# logging
log() {
    local level="$1"; shift

    # format: [LEVEL] YYYY-MM-DD HH:MM:SS message
    printf '[%s] %s %s\n' "$level" "$(date +'%Y-%m-%d %H:%M:%S')" "$*"
}

# exit or return based on whether script is sourced or executed.
# allows sub-scripts to exit cleanly when executed directly
exit_or_return() {
    # if sourced, return. if executed, exit
    local status="${1:-0}"
    local caller_index=0

    # BASH_SOURCE will have more than one entry if sourced
    if (( ${#BASH_SOURCE[@]} > 1 )); then
        caller_index=1
    fi

    # get the caller script name
    local caller="${BASH_SOURCE[$caller_index]:-}"

    if [[ "$caller" == "$0" ]]; then
        exit "$status"
    else
        return "$status"
    fi
}

# is app installed
is_app_installed() {
    if ! open -Ra "$1" >/dev/null 2>&1; then
        return 1
    else
        return 0
    fi
}

# is app running
is_app_running() {
    local app="$1"

    # Escape any double quotes in the app name to safely embed inside AppleScript
    local escaped_app="${app//\"/\\\"}"

    local result

    if ! result=$(
        osascript 2>/dev/null <<EOF
tell application "System Events"
    return (exists process "${escaped_app}")
end tell
EOF
    ); then
        # If osascript fails, treat as not running
        return 1
    fi

    # AppleScript returns 'true' or 'false'
    if [[ "$result" == "true" ]]; then
        return 0
    else
        return 1
    fi
}

# is the url already open in google chrome
is_url_open_in_chrome() {
    local url="$1"
    local escaped_url="${url//\"/\\\"}"
    local result

    if ! result=$(
        osascript 2>/dev/null <<EOF
if application "Google Chrome" is running then
    tell application "Google Chrome"
        repeat with w in windows
            repeat with t in tabs of w
                try
                    if (URL of t as string) is "${escaped_url}" then return true
                end try
            end repeat
        end repeat
    end tell
end if
return false
EOF
    ); then
        return 1
    fi

    if [[ "$result" == "true" ]]; then
        return 0
    else
        return 1
    fi
}

# is the url already open in any supported browser
is_url_open() {
    local url="$1"

    if is_url_open_in_chrome "$url"; then
        return 0
    fi

    return 1
}

# is CLI command installed
is_cmd_installed() {
    if ! command -v "$1" >/dev/null 2>&1; then
        return 1
    else
        return 0
    fi
}

# retry command until success or attempts exhausted
wait_for_success() {
    local attempts="$1" delay="$2"
    shift 2
    local attempt

    for ((attempt=1; attempt<=attempts; attempt++)); do
        if "$@"; then
            return 0
        fi
        (( attempt < attempts )) && sleep "$delay"
    done

    return 1
}

# wait for an app process to appear
wait_for_process() {
    local app="$1" attempts="${2:-20}" delay="${3:-1}"
    wait_for_success "$attempts" "$delay" is_app_running "$app"
}

# ensure config is loaded - if LAUNCH_BOX_CONFIG is not set, find a default
ensure_config_loaded() {
    if [[ -n "${LAUNCH_BOX_CONFIG:-}" ]]; then
        return 0
    fi

    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local project_root="$(dirname "$script_dir")"

    # try to find a config file in common locations
    if [[ -f "$project_root/launch-config.json" ]]; then
        export LAUNCH_BOX_CONFIG="$project_root/launch-config.json"
        log INFO "Using project root config: $LAUNCH_BOX_CONFIG"
        return 0
    elif [[ -f "$HOME/.launch-box/launch-config.json" ]]; then
        export LAUNCH_BOX_CONFIG="$HOME/.launch-box/launch-config.json"
        log INFO "Using user home config: $LAUNCH_BOX_CONFIG"
        return 0
    fi

    log ERROR "Config file not found."
    return 1
}

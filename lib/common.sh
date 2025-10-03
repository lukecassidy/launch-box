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

    # Use osascript to check for a running process
    if ! result=$(osascript <<EOF 2>/dev/null
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

    if ! result=$(osascript <<EOF 2>/dev/null
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

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

# is CLI command installed
is_cmd_installed() {
    if ! command -v "$1" >/dev/null 2>&1; then
        return 1
    else
        return 0
    fi
}

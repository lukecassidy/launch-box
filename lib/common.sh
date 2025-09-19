# logging
log() {
    local level="$1"; shift

    # format: [LEVEL] YYYY-MM-DD HH:MM:SS message
    printf '[%s] %s %s\n' "$level" "$(date +'%Y-%m-%d %H:%M:%S')" "$*"
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

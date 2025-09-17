
# logging
log() {
    local level="$1"; shift

    # format: [LEVEL] YYYY-MM-DD HH:MM:SS message
    printf '[%s] %s %s\n' "$level" "$(date +'%Y-%m-%d %H:%M:%S')" "$*"
}
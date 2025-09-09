#!/bin/bash
set -Eeuo pipefail
IFS=$'\n\t'

###############################################################################
# Description:
#     This script reads a config file that contains URLs and local mac app
#     names. It opens the URLs in the default browser and launches the apps
#     listed in the file. See README.md for more information.
#
# Usage: ./eat.sh --help
###############################################################################

# defaults
readonly DEFAULT_CONFIG="box.config"
DRY_RUN=false

# logger
log() {
    printf '%s %s\n' "$(date +'%Y-%m-%d %H:%M:%S')" "$1"
}

usage() {
    cat >&2 <<EOF
Usage: $(basename "$0") [options]

Options:
  -c, --config <file>   Path to config file (default: ${DEFAULT_CONFIG})
  -d, --dry-run         Print actions without opening anything
  -h, --help            Show this help and exit

Config format:
  # URLs
  https://tinyurl.com/muywa6ax   # optional inline comment
  https://www.google.com

  # APPS
  Visual Studio Code   # editor
  Slack                # chat

EOF
}

parse_args() {
    local cfg="${DEFAULT_CONFIG}"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -c|--config)
                # flag and value required
                [[ $# -lt 2 ]] && { log "[ERROR] Missing value for $1"; usage; exit 2; }
                cfg="$2"; shift 2 ;;
            -d|--dry-run)
                DRY_RUN=true; shift ;;
            -h|--help)
                usage; exit 0 ;;
            *)
                log "[ERROR] Unknown option: $1"; usage; exit 2 ;;
        esac
    done
    printf '%s\n' "$cfg"
}

# does config file exist
check_config_file() {
    if [[ ! -f "$1" ]]; then
        log "[ERROR] Config file '$1' not found!"
        return 1
    fi

    log "[INFO] Config file '$1' found."
    return 0
}

# validate URLs
is_valid_url() {
    if [[ "$1" =~ ^https?:// ]]; then
        return 0
    else
        return 1
    fi
}

# open URLs
open_urls() {
    log "[INFO] Opening URLs..."
    while IFS= read -r url; do
        # stop reading URLs at apps section
        [[ "$url" == "# APPS" ]] && break

        # ignore full comments and empty lines
        [[ -z "$url" || "$url" =~ ^[[:space:]]*#.*$ ]] && continue

        # strip inline comments and whitespace 
        local cleaned="${url%%#*}"
        cleaned="$(echo "$cleaned" | xargs)"
        [[ -z "$cleaned" ]] && continue

        # validate and open URL
        if is_valid_url "$cleaned"; then
            log "[INFO] Opening URL: '$cleaned'"
            if [[ "$DRY_RUN" == true ]]; then
                : # null command
            else
                open "$cleaned"
            fi
        else
            log "[WARNING] Invalid URL - '$cleaned'"
        fi
    done < "$1"
}

# check if an app installed
is_app_installed() {
    if ! open -Ra "$1" >/dev/null 2>&1; then
        return 1
    else
        return 0
    fi
}

# open apps
open_apps() {
    log "[INFO] Opening Applications..."
    local apps_section=false
    while IFS= read -r line; do
        # start reading apps at apps section (check raw line)
        if [[ "$line" == "# APPS" ]]; then
            apps_section=true
            continue
        fi

        # ignore full comments and empty lines
        [[ -z "$line" || "$line" =~ ^[[:space:]]*#.*$ ]] && continue

        if [[ "$apps_section" == true ]]; then

            # strip inline comments and whitespace
            local cleaned="${line%%#*}"
            cleaned="$(echo "$cleaned" | xargs)"
            [[ -z "$cleaned" ]] && continue

            if is_app_installed "$cleaned"; then
                log "[INFO] Opening application: '$cleaned'"
                if [[ "$DRY_RUN" == true ]]; then
                    : # no-op
                else
                    open -a "$cleaned"
                fi
            else
                log "[WARNING] Application not found - '$cleaned'"
            fi
        fi
    done < "$1"
}

main() {
    local config_file
    config_file="$(parse_args "$@")"
    log "[INFO] Unpacking l(a)unch box."
    check_config_file "$config_file" || exit 1
    log "[INFO] Nom nom nom."
    open_urls "$config_file"
    log "[INFO] Nom nom nom nom."
    open_apps "$config_file"
    log "[INFO] Nom nom nom nom nom."
    log "[INFO] Finished."
}

# l(a)unch time!
main "$@"

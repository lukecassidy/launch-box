#!/bin/bash
set -Eeuo pipefail

###############################################################################
# Description:
#     This script reads a config file that contains URLs and local mac app
#     names. It opens the URLs in the default browser and launches the apps
#     listed in the file. See README.md for more information.
#
# Usage: ./eat.sh --help
###############################################################################

# logging
log() {
    local level="$1"; shift
    printf '[%s] %s %s\n' "$level" "$(date +'%Y-%m-%d %H:%M:%S')" "$*"
}

usage() {
    cat >&2 <<EOF
Usage: $(basename "$0") [options]

Options:
  -c, --config <file>   Path to config file (default: box.config)
  -d, --dry-run         Print actions without opening anything
  -h, --help            Show this help and exit

Config format:
  # URLs
  https://tinyurl.com/muywa6ax   # optional inline comment
  https://www.google.com

  # APPS
  Visual Studio Code   # editor
  Slack                # chat
  iTerm

  # PLUGINS
  iTerm.sh             # custom script for app configuration

EOF
}

parse_args() {
    local cfg="box.config"
    local dry=0
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -c|--config)
                [[ $# -lt 2 ]] && { log ERROR "Missing value for $1"; usage; exit 2; }
                cfg="$2"; shift 2 ;;
            -d|--dry-run)
                dry=1; shift ;;
            -h|--help)
                usage; exit 0 ;;
            *)
                log ERROR "Unknown option: $1"; usage; exit 2 ;;
        esac
    done
    printf '%s %s\n' "$cfg" "$dry"
}

# does config file exist
check_config_file() {
    if [[ ! -f "$1" ]]; then
        log ERROR "Config file '$1' not found!"
        return 1
    fi

    log INFO "Config file '$1' found."
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
    local cfg="$1" dry="$2"
    log INFO "Opening URLs..."
    while IFS= read -r url; do
        # stop reading URLs at apps section
        [[ "$url" == "# APPS" ]] && break

        # ignore full comments and empty lines
        [[ -z "$url" || "$url" =~ ^[[:space:]]*#.*$ ]] && continue

        local cleaned
        cleaned=$(clean_line "$url")
        [[ -z "$cleaned" ]] && continue

        # validate and open URL
        if is_valid_url "$cleaned"; then
            log INFO "Opening URL: '$cleaned'"
            if (( dry )); then
                : # null command (dry run)
            else
                open "$cleaned"
            fi
        else
            log WARNING "Invalid URL - '$cleaned'"
        fi
    done < "$cfg"
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
    local cfg="$1" dry="$2"
    log INFO "Opening Applications..."
    local apps_section=false
    while IFS= read -r line; do
        # start reading apps at apps section (check raw line)
        if [[ "$line" == "# APPS" ]]; then
            apps_section=true
            continue
        fi

        # stop reading APPS at plugins section
        [[ "$line" == "# PLUGINS" ]] && break

        # ignore full comments and empty lines
        [[ -z "$line" || "$line" =~ ^[[:space:]]*#.*$ ]] && continue

        if [[ "$apps_section" == true ]]; then

            # strip inline comments and whitespace
            local cleaned
            cleaned=$(clean_line "$line")
            [[ -z "$cleaned" ]] && continue

            if is_app_installed "$cleaned"; then
                log INFO "Opening application: '$cleaned'"
                if (( dry )); then
                    : # no-op (dry run)
                else
                    open -a "$cleaned"
                fi
            else
                log WARNING "Application not found - '$cleaned'"
            fi
        fi
    done < "$cfg"
}

configure_apps() {
    local cfg="$1" dry="$2"
    log INFO "Configuring Applications..."
    local plugins_section=false
    while IFS= read -r line; do
        # start reading plugins at plugins section (check raw line)
        if [[ "$line" == "# PLUGINS" ]]; then
            plugins_section=true
            continue
        fi

        # ignore full comments and empty lines
        [[ -z "$line" || "$line" =~ ^[[:space:]]*#.*$ ]] && continue

        if [[ "$plugins_section" == true ]]; then

            # strip inline comments and whitespace
            local cleaned
            cleaned=$(clean_line "$line")
            [[ -z "$cleaned" ]] && continue

            # check if plugin script exists
            if [[ -f "plugins/$cleaned.sh" ]]; then
                log INFO "Running plugin script: '$cleaned'"
                if (( dry )); then
                    : # no-op (dry run)
                else
                    source "plugins/$cleaned.sh"
                fi
            else
                log WARNING "Plugin script not found - '$cleaned'"
            fi
        fi
    done < "$cfg"
}

clean_line() {
    local line="$1"
    line="${line%%[[:space:]]#*}"   # strip inline comments
    echo "$line" | xargs            # trim whitespace
}

main() {
    local config_file dry_run
    read -r config_file dry_run < <(parse_args "$@")
    log INFO "Unpacking l(a)unch box."
    check_config_file "$config_file" || exit 1
    log INFO "Nom nom nom."
    open_urls "$config_file" "$dry_run"
    log INFO "Nom nom nom nom."
    open_apps "$config_file" "$dry_run"
    log INFO "Nom nom nom nom nom."
    configure_apps "$config_file" "$dry_run"
    log INFO "Nom nom nom nom nom nom."
    log INFO "Finished."
}

# l(a)unch time!
main "$@"

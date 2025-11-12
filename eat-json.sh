#!/bin/bash
set -Eeuo pipefail

###############################################################################
# Description:
#     This script reads a JSON config file (box.json) that contains URLs,
#     app names, and plugins. It opens URLs, launches apps, and runs plugins.
#
# Usage: ./eat-json.sh [options]
###############################################################################

# Redirect all output to log file, while still printing to console
LOG_FILE="$(dirname "${BASH_SOURCE[0]}")/launch-box.log"

# Rotate log if it grows larger than 1 MB
if [[ -f "$LOG_FILE" && $(wc -c <"$LOG_FILE") -gt 1048576 ]]; then
    mv "$LOG_FILE" "${LOG_FILE}-old.log"
fi

exec > >(tee -a "$LOG_FILE") 2>&1

source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

usage() {
    cat >&2 <<EOF
Usage: $(basename "$0") [options]

Options:
  -c, --config <file>   Path to config file (default: box.json)
  -d, --dry-run         Print actions without opening anything
  -h, --help            Show this help and exit

Config format (JSON):
  {
    "urls": [
      "https://calendar.google.com",
      "https://mail.google.com"
    ],
    "apps": [
      "Visual Studio Code",
      "Slack",
      "iTerm"
    ],
    "plugins": [
      "iTerm",
      "layout"
    ]
  }

EOF
}

# parse command line arguments
parse_args() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local cfg="$script_dir/box.json"
    local dry=0
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -c|--config)
                [[ $# -lt 2 ]] && { log ERROR "Missing value for $1"; usage; exit 2; }
                cfg="$2"; shift 2 ;;
            -d|--dry-run)
                dry=1; shift ;;
            *)
                log ERROR "Unknown option: $1"; usage; exit 2 ;;
        esac
    done

    # Output parsed vals to stdout for caller capture.
    echo "$cfg $dry"
}

# does config file exist
check_config_file() {
    log INFO "Checking config file '$1'..."
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

# check if core dependencies are installed
check_core_dependencies() {
    local -a deps=(open jq)
    local -a missing=()

    for dep in "${deps[@]}"; do
        if ! is_cmd_installed "$dep"; then
            missing+=("$dep")
        fi
    done

    if ((${#missing[@]})); then
        log ERROR "Missing core dependencies: ${missing[*]}"
        return 1
    fi

    log INFO "All core dependencies are installed."
    return 0
}

# open URLs
open_urls() {
    local cfg="$1" dry="$2"
    log INFO "Opening URLs..."
    local urls
    urls=$(jq -r '.urls[]?' "$cfg" 2>/dev/null)

    if [[ -z "$urls" ]]; then
        log INFO "No URLs configured."
        return 0
    fi

    while IFS= read -r url; do
        [[ -z "$url" ]] && continue

        # validate and open URL
        if is_valid_url "$url"; then
            if is_url_open "$url"; then
                log INFO "URL already open: '$url'"
                continue
            fi

            log INFO "Opening URL: '$url'"
            if (( dry )); then
                : # null command (dry run)
            else
                open "$url"
            fi
        else
            log WARNING "Invalid URL - '$url'"
        fi
    done <<< "$urls"
}

# launch apps
open_apps() {
    local cfg="$1" dry="$2"
    log INFO "Opening Applications..."
    local apps
    apps=$(jq -r '.apps[]?' "$cfg" 2>/dev/null)

    if [[ -z "$apps" ]]; then
        log INFO "No apps configured."
        return 0
    fi

    while IFS= read -r app; do
        [[ -z "$app" ]] && continue

        if is_app_installed "$app"; then
            if is_app_running "$app"; then
                log INFO "Application already running: '$app'"
                continue
            fi

            log INFO "Opening application: '$app'"
            if (( dry )); then
                : # no-op (dry run)
            else
                open -a "$app"
            fi
        else
            log WARNING "Application not found - '$app'"
        fi
    done <<< "$apps"
}

# configure apps via plugins
configure_apps() {
    local cfg="$1" dry="$2"
    log INFO "Configuring Applications..."
    local plugins
    plugins=$(jq -r '.plugins[]?' "$cfg" 2>/dev/null)

    if [[ -z "$plugins" ]]; then
        log INFO "No plugins configured."
        return 0
    fi

    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    while IFS= read -r plugin; do
        [[ -z "$plugin" ]] && continue

        if [[ -f "$script_dir/plugins/$plugin.sh" ]]; then
            log INFO "Running plugin script: '$plugin'"
            if (( dry )); then
                : # no-op (dry run)
            else
                source "$script_dir/plugins/$plugin.sh"
            fi
        else
            log WARNING "Plugin script not found - '$plugin'"
        fi
    done <<< "$plugins"
}

# main
main() {
    local cfg dry_run

    # handle help before anything else
    for arg in "$@"; do
        if [[ "$arg" == "-h" || "$arg" == "--help" ]]; then
            usage
            exit 0
        fi
    done

    log INFO "Unpacking l(a)unch box."

    # parse command line arguments
    local parsed
    parsed=$(parse_args "$@")
    read -r cfg dry_run <<< "$parsed"

    log INFO "Checking core dependencies..."
    check_core_dependencies || exit 1

    log INFO "Checking config file: '$cfg'..."
    check_config_file "$cfg" || exit 1

    # open URLs
    log INFO "Nom nom nom."
    open_urls "$cfg" "$dry_run"

    # open apps
    log INFO "Nom nom nom nom."
    open_apps "$cfg" "$dry_run"
    sleep 2 # wait for apps to launch

    # configure apps
    log INFO "Nom nom nom nom nom."
    configure_apps "$cfg" "$dry_run"

    log INFO "Nom nom nom nom nom nom."
    log INFO "Finished."
}

# l(a)unch time!
main "$@"

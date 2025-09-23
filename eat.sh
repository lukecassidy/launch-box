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

source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

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
  iTerm       # Run plugin script to configure iTerm (split panes, run commands etc)
  layout      # Run plugin script to arrange windows/screens

EOF
}

# parse command line arguments
parse_args() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local cfg="$script_dir/box.config"
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
    local missing=0
    dependencies=(open xargs)
    for dep in "${dependencies[@]}"; do
        is_cmd_installed "$dep" || missing=1
        deps+=("$dep")
    done

    if (( missing )); then
        log ERROR "Missing core dependencies: ${deps[*]}"
        return 1
    fi
    return 0
}

# strip inline comments and trim whitespace from a line
clean_line() {
    local line="$1"
    line="${line%%[[:space:]]#*}"
    echo "$line" | xargs
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
            if is_url_open "$cleaned"; then
                log INFO "URL already open: '$cleaned'"
                continue
            fi

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

# launch apps
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
                if is_app_running "$cleaned"; then
                    log INFO "Application already running: '$cleaned'"
                    continue
                fi

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

# configure apps via plugins
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
            local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
            if [[ -f "$script_dir/plugins/$cleaned.sh" ]]; then
                log INFO "Running plugin script: '$cleaned'"
                if (( dry )); then
                    : # no-op (dry run)
                else
                    source "$script_dir/plugins/$cleaned.sh"
                fi
            else
                log WARNING "Plugin script not found - '$cleaned'"
            fi
        fi
    done < "$cfg"
}

main() {
    local config_file dry_run
    log INFO "Unpacking l(a)unch box."

    # parse command line arguments
    read -r config_file dry_run < <(parse_args "$@")

    log INFO "Checking core dependencies..."
    if ! check_core_dependencies; then
        exit 1
    fi

    log INFO "Checking config file: '$config_file'..."
    if ! check_config_file "$config_file"; then
        exit 1
    fi

    # open URLs
    log INFO "Nom nom nom."
    open_urls "$config_file" "$dry_run"
    sleep 2 # wait for URLs to open

    # open apps
    log INFO "Nom nom nom nom."
    open_apps "$config_file" "$dry_run"
    sleep 2 # wait for apps to launch

    # configure apps
    log INFO "Nom nom nom nom nom."
    configure_apps "$config_file" "$dry_run"

    log INFO "Nom nom nom nom nom nom."
    log INFO "Finished."
}

# l(a)unch time!
main "$@"

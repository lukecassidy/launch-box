#!/bin/bash
set -Eeuo pipefail

###############################################################################
# Description:
#     This script reads a config file containing URLs, app names and plugins.
#
# Usage: ./eat.sh [options]
###############################################################################

# redirect all output to log file, while still printing to console
LOG_FILE="$(dirname "${BASH_SOURCE[0]}")/launch-box.log"

# rotate log if it grows larger than 1 MB
if [[ -f "$LOG_FILE" && $(wc -c <"$LOG_FILE")" -gt 1048576 ]]; then
    mv "$LOG_FILE" "${LOG_FILE}-old.log"
fi

exec > >(tee -a "$LOG_FILE") 2>&1

source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

usage() {
    cat >&2 <<EOF
Usage: $(basename "$0") [options]

Options:
  -c, --config <file>   Path to config file (default: launch-config.json)
  -d, --dry-run         Print actions without opening anything
  -h, --help            Show this help and exit

Config file example:
  {
    "urls": [
      "https://calendar.google.com"
    ],
    "apps": [
      "Visual Studio Code",
      "Slack",
      "iTerm"
    ],
    "plugins": {
      "code": {},
      "iTerm": {
        "panes": [
          "clear; figlet luke",
          "clear; figlet is",
          "clear; figlet cool"
        ]
      }
    },
    "layouts": {
      "single": {
        "Built-in Retina Display": [
          { "slot": "lft_half_all", "app": "code" },
          { "slot": "rgt_half_all", "app": "Slack" }
        ]
      }
    }
  }

EOF
}

# parse command line arguments
parse_args() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local config_file="$script_dir/launch-config.json"
    local dry=0
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -c|--config)
                [[ $# -lt 2 ]] && { log ERROR "Missing value for $1"; usage; exit 2; }
                config_file="$2"; shift 2 ;;
            -d|--dry-run)
                dry=1; shift ;;
            *)
                log ERROR "Unknown option: $1"; usage; exit 2 ;;
        esac
    done

    # output parsed vals to stdout for caller capture.
    echo "$config_file $dry"
}

# check and validate config file
check_config_file() {
    log INFO "Checking config file '$1'..."

    # check file exists
    if [[ ! -f "$1" ]]; then
        log ERROR "Config file '$1' not found!"
        return 1
    fi

    # validate JSON syntax
    local count
    count=$(jq '(.urls // [] | length) + (.apps // [] | length)' "$1" 2>&1) || {
        log ERROR "Config file contains invalid JSON syntax."
        return 1
    }

    # warn if no URLs or apps defined
    if [[ "$count" -eq 0 ]]; then
        log WARNING "Config file is empty or has no URLs/apps defined"
    fi

    log INFO "Config file validated."
}

# parse config file once and return all data
parse_config() {
    local config_file="$1"

    # parse entire config at once using jq
    jq -r '{
        urls: [.urls[]? // empty],
        apps: [.apps[]? // empty],
        plugins: [.plugins // {} | keys[]],
        layouts: .layouts
    }' "$config_file" 2>/dev/null
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
    local urls="$1" dry="$2"
    log INFO "Opening URLs..."

    if [[ -z "$urls" || "$urls" == "null" ]]; then
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
    local apps="$1" dry="$2"
    log INFO "Opening Applications..."

    if [[ -z "$apps" || "$apps" == "null" ]]; then
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
    local plugins="$1" config_file="$2" dry="$3"
    log INFO "Configuring Applications..."

    if [[ -z "$plugins" || "$plugins" == "null" ]]; then
        log INFO "No plugins configured."
        return 0
    fi

    # Export config path for plugins to use
    export LAUNCH_BOX_CONFIG="$config_file"

    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    while IFS= read -r plugin; do
        [[ -z "$plugin" ]] && continue

        local plugin_path="$script_dir/plugins/$plugin.sh"
        if [[ -f "$plugin_path" ]]; then
            log INFO "Running plugin script: '$plugin'"
            if (( dry )); then
                : # no-op (dry run)
            else
                source "$plugin_path"
            fi
        else
            log WARNING "Plugin script not found - '$plugin'"
        fi
    done <<< "$plugins"
}

# configure window layouts via Hammerspoon
configure_layouts() {
    local config_file="$1" dry="$2"
    log INFO "Configuring Layouts..."

    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local layout_script="$script_dir/layout/layout.sh"

    # check if layout script exists
    if [[ ! -f "$layout_script" ]]; then
        log INFO "Layout script not found, skipping window layout configuration"
        return 0
    fi

    # symlink config for Hammerspoon to read
    if (( ! dry )); then
        local config_json
        config_json="$(cd "$(dirname "$config_file")" && pwd)/$(basename "$config_file")"
        local hs_config_link="$HOME/.hammerspoon/plugins/launch-box-config.json"
        mkdir -p "$(dirname "$hs_config_link")"
        ln -sf "$config_json" "$hs_config_link"
        log INFO "Config linked for Hammerspoon: $config_json"
    fi

    # Run layout script
    if (( dry )); then
        log INFO "Would run layout configuration"
    else
        source "$layout_script"
    fi
}

# main
main() {
    local config_file dry_run

    # handle help before anything else
    for arg in "$@"; do
        if [[ "$arg" == "-h" || "$arg" == "--help" ]]; then
            usage
            exit 0
        fi
    done

    log INFO "Unpacking l(a)unch box."

    # parse command line arguments
    local args
    args=$(parse_args "$@")
    read -r config_file dry_run <<< "$args"

    log INFO "Checking config file: '$config_file'..."
    check_config_file "$config_file" || exit 1

    log INFO "Checking core dependencies..."
    check_core_dependencies || exit 1

    # parse config once
    log INFO "Parsing config file..."
    local config_data
    config_data=$(parse_config "$config_file") || exit 1

    # extract parsed data
    local urls apps plugins
    urls=$(echo "$config_data" | jq -r '.urls[]?' 2>/dev/null)
    apps=$(echo "$config_data" | jq -r '.apps[]?' 2>/dev/null)
    plugins=$(echo "$config_data" | jq -r '.plugins[]?' 2>/dev/null)

    # open URLs
    open_urls "$urls" "$dry_run"

    # open apps
    open_apps "$apps" "$dry_run"
    sleep 2 # wait for apps to launch

    # configure apps
    configure_apps "$plugins" "$config_file" "$dry_run"

    # configure layouts
    configure_layouts "$config_file" "$dry_run"

    log INFO "Finished."
}

# launch time!
main "$@"
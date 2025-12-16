#!/bin/bash
set -Eeuo pipefail

###############################################################################
# Description:
#     This script reads a config file containing URLs, app names and plugins.
#
# Usage: ./launch-box.sh [options]
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAUNCH_BOX_HOME="$HOME/.launch-box"
LOG_FILE="$LAUNCH_BOX_HOME/launch-box.log"
mkdir -p "$LAUNCH_BOX_HOME"

if [[ -f "$LOG_FILE" && $(wc -c <"$LOG_FILE") -gt 1048576 ]]; then
    mv "$LOG_FILE" "${LOG_FILE}.old"
fi

exec > >(tee -a "$LOG_FILE") 2>&1

source "$SCRIPT_DIR/lib/common.sh"

usage() {
    cat >&2 <<EOF
Usage: $(basename "$0") [options]

Options:
  -c, --config <file>   Path to config file (default: ~/.launch-box/launch-config.json)
  -d, --dry-run         Print actions without opening anything
  -h, --help            Show this help and exit

Config file: $LAUNCH_BOX_HOME/launch-config.json
Log file:    $LAUNCH_BOX_HOME/launch-box.log

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

# setup user config on first run
setup_user_config() {
    local user_config="$LAUNCH_BOX_HOME/launch-config.json"
    local example_config="$SCRIPT_DIR/launch-config.example.json"

    # if user config doesn't exist but example does, copy it
    if [[ ! -f "$user_config" && -f "$example_config" ]]; then
        log INFO "First run detected. Setting up user config..."
        cp "$example_config" "$user_config"

        log INFO "Config file created at: $user_config"
        log INFO "You can customise this file for your setup."
    fi
}

# parse command line arguments
parse_args() {
    local config_file="$LAUNCH_BOX_HOME/launch-config.json"
    local dry_run=0
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -c|--config)
                [[ $# -lt 2 ]] && { log ERROR "Missing value for $1"; usage; exit 2; }
                config_file="$2"; shift 2 ;;
            -d|--dry-run)
                dry_run=1; shift ;;
            *)
                log ERROR "Unknown option: $1"; usage; exit 2 ;;
        esac
    done

    # output parsed vals to stdout for caller capture
    echo "$config_file $dry_run"
}

# validate field type helper
validate_field_type() {
    local config="$1" field="$2" expected_type="$3"

    if ! jq -e "(.$field == null) or (.$field | type == \"$expected_type\")" "$config" >/dev/null 2>&1; then
        log ERROR "Config validation failed: '$field' must be $expected_type"
        return 1
    fi
}

# validate URL format helper
validate_url_format() {
    local config="$1"

    # skip if urls field doesn't exist
    if ! jq -e '.urls' "$config" >/dev/null 2>&1; then
        return 0
    fi

    # verify all URLs are valid strings with http(s) protocol
    if ! jq -e '.urls | all(type == "string" and (startswith("http")))' "$config" >/dev/null 2>&1; then
        log ERROR "Config validation failed: URLs must begin with http:// or https://"
        return 1
    fi
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
    if ! jq empty "$1" 2>/dev/null; then
        log ERROR "Config file contains invalid JSON syntax."
        return 1
    fi

    # validation checks
    validate_field_type "$1" "urls" "array" || return 1
    validate_field_type "$1" "apps" "array" || return 1
    validate_field_type "$1" "plugins" "object" || return 1
    validate_field_type "$1" "layouts" "object" || return 1
    validate_url_format "$1" || return 1

    # warn if no URLs or apps defined
    local count
    count=$(jq '(.urls // [] | length) + (.apps // [] | length)' "$1" 2>/dev/null)
    if [[ "$count" -eq 0 ]]; then
        log WARNING "Config file is empty or has no URLs/apps defined"
    fi

    log INFO "Config file validated."
}

# check if core dependencies are installed
check_core_dependencies() {
    log INFO "Checking core dependencies..."
    local -a deps=(open jq)
    local -a missing=()

    for dep in "${deps[@]}"; do
        if ! is_cmd_installed "$dep"; then
            missing+=("$dep")
        fi
    done

    if (( ${#missing[@]} > 0 )); then
        log ERROR "Missing core dependencies: ${missing[*]}"
        return 1
    fi

    log INFO "All core dependencies are installed."
    return 0
}

# open URLs
open_urls() {
    local urls="$1" dry_run="$2"
    log INFO "Opening URLs..."

    if [[ -z "$urls" || "$urls" == "null" ]]; then
        log INFO "No URLs configured."
        return 0
    fi

    while IFS= read -r url; do
        [[ -z "$url" ]] && continue

        if is_url_open "$url"; then
            log INFO "URL already open: '$url'"
            continue
        fi

        log INFO "Opening URL: '$url'"
        if (( dry_run )); then
            : # no-op (dry run)
        else
            open "$url"
        fi
    done <<< "$urls"
}

# launch apps
open_apps() {
    local apps="$1" dry_run="$2"
    log INFO "Opening Applications..."

    if [[ -z "$apps" || "$apps" == "null" ]]; then
        log INFO "No apps configured."
        return 0
    fi

    # track which apps we actually launched
    LAUNCHED_APPS=()

    while IFS= read -r app; do
        [[ -z "$app" ]] && continue

        if is_app_installed "$app"; then
            if is_app_running "$app"; then
                log INFO "Application already running: '$app'"
                continue
            fi

            log INFO "Opening application: '$app'"
            if (( dry_run )); then
                : # no-op (dry run)
            else
                open -a "$app"
                LAUNCHED_APPS+=("$app")
            fi
        else
            log WARNING "Application not found - '$app'"
        fi
    done <<< "$apps"
}

# configure apps via plugins
configure_apps() {
    local plugins="$1" config_file="$2" dry_run="$3"
    log INFO "Configuring Applications..."

    if [[ -z "$plugins" || "$plugins" == "null" ]]; then
        log INFO "No plugins configured."
        return 0
    fi

    # export config path for plugins to use
    export LAUNCH_BOX_CONFIG="$config_file"

    while IFS= read -r plugin; do
        [[ -z "$plugin" ]] && continue

        local plugin_path="$SCRIPT_DIR/plugins/$plugin.sh"
        if [[ -f "$plugin_path" ]]; then
            log INFO "Running plugin script: '$plugin'"
            if (( dry_run )); then
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
    local config_file="$1" dry_run="$2"
    log INFO "Configuring Layouts..."

    local layout_script="$SCRIPT_DIR/layout/layout.sh"

    # check if layout script exists
    if [[ ! -f "$layout_script" ]]; then
        log INFO "Layout script not found, skipping window layout configuration"
        return 0
    fi

    # symlink config for Hammerspoon to read
    if (( ! dry_run )); then
        local config_json
        config_json="$(cd "$(dirname "$config_file")" && pwd)/$(basename "$config_file")"
        local hs_config_link="$HOME/.hammerspoon/plugins/launch-box-config.json"
        mkdir -p "$(dirname "$hs_config_link")"
        ln -sf "$config_json" "$hs_config_link"
        log INFO "Config linked for Hammerspoon: $config_json"
    fi

    # run layout script
    if (( dry_run )); then
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

    # setup user config on first run
    setup_user_config

    # parse command line arguments
    local args
    args=$(parse_args "$@")
    read -r config_file dry_run <<< "$args"

    # check config file and core dependencies
    check_config_file "$config_file" || exit 1
    check_core_dependencies || exit 1

    # extract config data
    local urls apps plugins
    urls=$(jq -r '.urls[]?' "$config_file" 2>/dev/null)
    apps=$(jq -r '.apps[]?' "$config_file" 2>/dev/null)
    plugins=$(jq -r '.plugins | keys[]?' "$config_file" 2>/dev/null)

    # open URLs
    open_urls "$urls" "$dry_run"

    # open apps
    open_apps "$apps" "$dry_run"

    # wait for apps to launch
    if (( ${#LAUNCHED_APPS[@]} > 0 )) && ! (( dry_run )); then
        sleep 1
    fi

    # configure apps
    configure_apps "$plugins" "$config_file" "$dry_run"

    # configure layouts
    configure_layouts "$config_file" "$dry_run"

    log INFO "Finished."
}

# launch time!
main "$@"
#!/bin/bash
set -Eeuo pipefail
IFS=$'\n\t'

###############################################################################
# Script Name: 
#     eat.sh
#
# Description:
#     This script reads a config file that contains URLs and local mac app
#     names. It opens the URLs in the default browser and launches the apps
#     listed in the file.
#
# Configuration File Format:
#     Urls and apps are listed one per line, split into sections.
#
# Usage:
#     ./eat.sh
#
# Example Config File (pack.config):
#     # URLs
#     https://tinyurl.com/muywa6ax
#     https://www.google.com
#
#     # APPS
#     Visual Studio Code
#     Slack
#
# TODO:
#     Convert config file to yaml or json.
#     Add section for app configuration. Example: iTerm2 panes.
#     Tidy up logic around file reading.
###############################################################################

# config file
config_file="pack.config"

# logger
log() {
    printf '%s - %s\n' "$(date +'%Y-%m-%d %H:%M:%S')" - "$1"
}

# does config file exist
check_config_file() {
    if [[ ! -f "$config_file" ]]; then
        log "ERROR: Config file '$config_file' not found!"
        return 1
    
    log "Config file '$config_file' found."
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
    log "Opening URLs..."
    while IFS= read -r url; do
        # stop reading URLs at apps section
        [[ "$url" == "# APPS" ]] && break

        # ignore empty lines and comments
        [[ -z "$url" || "$url" =~ ^#.*$ ]] && continue

        # validate and open URL
        if is_valid_url "$url"; then
            log "Opening URL: '$url'"
            open "$url"
        else
            log "ERROR: Invalid URL - '$url'"
        fi
    done < "$config_file"
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
    log "Opening Applications..."
    apps_section=false
    while IFS= read -r line; do

        # start reading apps at apps section
        if [[ "$line" == "# APPS" ]]; then
            apps_section=true
            continue
        fi

        # ignore empty lines and comments
        [[ -z "$line" || "$line" =~ ^#.*$ ]] && continue

        # validate and open
        if [[ "$apps_section" == true ]]; then
            if is_app_installed "$line"; then
                log "Opening application: '$line'"
                open -a "$line"
            else
                log "ERROR: Application not found - '$line'"
            fi
        fi
    done < "$config_file"
}

main() {
    log "Unpacking l(a)unch box."
    check_config_file || exit 1
    log "Nom nom nom."
    open_urls
    log "Nom nom nom nom."
    open_apps
    log "Nom nom nom nom nom."
    log "Finished."
}

# l(a)unch time!
main
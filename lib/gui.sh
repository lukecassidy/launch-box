#!/bin/bash

###############################################################################
# A small wrapper lib for launching GUI aware commands from Shortcuts or other
# non-interactive contexts.
#
# Shortcuts starts processes under launchd where:
#   - stdout/stderr/stdin/PATH can differ from a login shell.
#   - the GUI session may not be attached.
#
# This wrapper lib helps by:
#   - Storing the Aqua session UID so work lands on the logged-in desktop
#   - Pinning a reliable PATH so Homebrew and user tools resolve
#   - Wrapping AppleScript runs so they survive when stdin disappears
#   - Wrapping `open` helpers that always target the GUI session
###############################################################################

# Safe PATH for GUI session commands
: "${GUI_SESSION_PATH:=${PATH:-/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin}}"

# Store GUI session UID for reuse.
__gui_uid="${__gui_uid:-$(stat -f '%u' /dev/console 2>/dev/null || id -u)}"

# Run command as GUI user with safe PATH
gui_run() {
    local path_value="$GUI_SESSION_PATH"
    if [[ "$(id -u)" -ne "$__gui_uid" ]]; then
        /bin/launchctl asuser "$__gui_uid" env PATH="$path_value" "$@" && return 0
    fi
    PATH="$path_value" "$@"
}

# Run AppleScript in GUI session.
gui_run_applescript() (
    tmp_file=$(mktemp -t gui_applescript.XXXXXX) || return 1

    # Ensure the temp file is removed
    trap 'rm -f "$tmp_file"' RETURN

    cat >"$tmp_file" || return 1
    gui_run osascript "$tmp_file"
)

# Open a file, URL or app in the logged in GUI session via `open`.
gui_open() {
    if [[ $# -eq 0 ]]; then
        log ERROR "gui_open requires at least one argument."
        return 1
    fi

    if [[ "$1" == -a ]] && [[ $# -lt 2 ]]; then
        log ERROR "gui_open $1 requires an app name."
        return 1
    fi

    gui_run open "$@"
}
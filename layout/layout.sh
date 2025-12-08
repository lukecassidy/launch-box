#!/bin/bash

###############################################################################
# Apply window layout via Hammerspoon
#
# Requires:
#   - Hammerspoon app installed
#   - Hammerspoon CLI hs installed (`hs.ipc.cliInstall()`)
# Install:
#       brew install --cask hammerspoon
#       Enable Accessibility permissions for Hammerspoon in:
#           System Preferences > Security & Privacy > Privacy > Accessibility
###############################################################################

plugin_dir="$(dirname "${BASH_SOURCE[0]}")"
source "$plugin_dir/../lib/common.sh"

log INFO "Layout plugin running..."

# constants
HS_APP="Hammerspoon"
HS_CLI="${HS_CLI:-/opt/homebrew/bin/hs}"

# timeout config
IPC_STARTUP_ATTEMPTS=10        # attempts to wait for IPC after app starts
IPC_STARTUP_DELAY=1            # seconds between IPC checks
IPC_VERIFY_ATTEMPTS=5          # attempts to verify existing IPC connection
IPC_VERIFY_DELAY=1             # seconds between verify checks
SHUTDOWN_ATTEMPTS=5            # attempts to wait for clean shutdown
SHUTDOWN_DELAY=0.2             # seconds between shutdown checks
PROCESS_START_ATTEMPTS=10      # attempts to wait for process to start
PROCESS_START_DELAY=1          # seconds between process checks

# check dependencies and skip if missing
check_dependencies() {
    local -a missing=()
    is_cmd_installed "$HS_CLI" || missing+=("hs CLI at $HS_CLI")
    is_app_installed "$HS_APP" || missing+=("$HS_APP app")

    if (( ${#missing[@]} )); then
        log ERROR "Skipping layout: missing dependencies: ${missing[*]}"
        exit_or_return 0
    fi
}

check_dependencies

# ensure Hammerspoon config symlink exists
ensure_hammerspoon_config_linked() {
    local repo_cfg="$plugin_dir/hammerspoon.lua"
    local target_cfg="$HOME/.hammerspoon/init.lua"

    if [[ "$(readlink "$target_cfg")" != "$(realpath "$repo_cfg")" ]]; then
        log INFO "Linking Hammerspoon config → $target_cfg"
        mkdir -p "$(dirname "$target_cfg")"
        ln -sf "$(realpath "$repo_cfg")" "$target_cfg"
        return 1 # config changed
    fi
    return 0 # no change
}

# check if config changed (triggers Hammerspoon restart if needed)
if ensure_hammerspoon_config_linked; then
    config_changed=0
else
    config_changed=1
fi

# IPC readiness check function
is_hs_ipc_ready() {
    "$HS_CLI" -c "return 'ok'" >/dev/null 2>&1
}

# check if app is NOT running (helper for waiting for shutdown)
is_hs_stopped() {
    ! is_app_running "$HS_APP"
}

# wait for IPC to become available with error handling
wait_for_ipc() {
    log INFO "Waiting for Hammerspoon IPC to initialize..."
    if ! wait_for_success "$IPC_STARTUP_ATTEMPTS" "$IPC_STARTUP_DELAY" is_hs_ipc_ready; then
        log ERROR "Hammerspoon IPC not available."
        exit_or_return 1
    fi
}

# start Hammerspoon and wait for IPC
start_hammerspoon() {
    log INFO "Starting $HS_APP..."
    open -a "$HS_APP"
    wait_for_process "$HS_APP" "$PROCESS_START_ATTEMPTS" "$PROCESS_START_DELAY" || {
        log ERROR "$HS_APP failed to launch."
        exit_or_return 1
    }
    wait_for_ipc
}

# restart Hammerspoon with clean shutdown
restart_hammerspoon() {
    log INFO "Restarting $HS_APP..."
    killall "$HS_APP" 2>/dev/null
    wait_for_success "$SHUTDOWN_ATTEMPTS" "$SHUTDOWN_DELAY" is_hs_stopped || log WARNING "$HS_APP may not have fully terminated"
    open -a "$HS_APP"
    wait_for_process "$HS_APP" "$PROCESS_START_ATTEMPTS" "$PROCESS_START_DELAY" || {
        log ERROR "$HS_APP failed to restart."
        exit_or_return 1
    }
    wait_for_ipc
}

# verify IPC is available for already-running instance
verify_ipc() {
    log INFO "Verifying Hammerspoon IPC..."
    if ! wait_for_success "$IPC_VERIFY_ATTEMPTS" "$IPC_VERIFY_DELAY" is_hs_ipc_ready; then
        ipc_output="$("$HS_CLI" -c "return 'ok'" 2>&1)"
        log ERROR "Hammerspoon IPC not available."
        [[ -n "$ipc_output" ]] && log ERROR "Last IPC error: $ipc_output"
        exit_or_return 1
    fi
}

# ensure Hammerspoon is running and IPC is available
if ! is_app_running "$HS_APP"; then
    start_hammerspoon
elif (( config_changed )); then
    restart_hammerspoon
else
    verify_ipc
fi

log INFO "Hammerspoon IPC ready."

# apply layout
log INFO "Applying window layout via Hammerspoon..."
if ! apply_output="$("$HS_CLI" -c "applyWorkspace()" 2>&1)"; then
    log ERROR "Failed to apply Hammerspoon workspace layout."
    [[ -n "$apply_output" ]] && log ERROR "Hammerspoon output: $apply_output"
    exit_or_return 1
fi

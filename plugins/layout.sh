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

# Hammerspoon CLI location
HS_CLI="${HS_CLI:-/opt/homebrew/bin/hs}"
LUA_BIN="${LUA_BIN:-/opt/homebrew/bin/lua}"

# Check dependencies and skip if missing
if ! is_cmd_installed "$HS_CLI"; then
    log ERROR "Skipping layout: hs CLI not found at $HS_CLI"
    exit_or_return 0
fi
if ! is_cmd_installed "$LUA_BIN"; then
    log ERROR "Skipping layout: lua not installed"
    exit_or_return 0
fi
if ! is_app_installed Hammerspoon; then
    log ERROR "Skipping layout: Hammerspoon not installed"
    exit_or_return 0
fi

# Ensure Hammerspoon config symlink exists
repo_cfg="$plugin_dir/hammerspoon.lua"
target_cfg="$HOME/.hammerspoon/init.lua"

if [[ "$(readlink "$target_cfg")" != "$(realpath "$repo_cfg")" ]]; then
    log INFO "Linking Hammerspoon config → $target_cfg"
    mkdir -p "$(dirname "$target_cfg")"
    ln -sf "$(realpath "$repo_cfg")" "$target_cfg"
else
    log INFO "Hammerspoon config link already correct."
fi

# Ensure Hammerspoon is running
if ! is_app_running "Hammerspoon"; then
    log INFO "Starting Hammerspoon..."
    open -a Hammerspoon
fi

if ! wait_for_process "Hammerspoon" 10 1; then
    log ERROR "Hammerspoon failed to launch."
    exit_or_return 1
fi

# Wait for Hammerspoon IPC to become available
is_hs_ipc_ready() {
    "$HS_CLI" -c "return 'ok'" >/dev/null 2>&1
}

log INFO "Waiting for Hammerspoon IPC..."
if wait_for_success 5 1 is_hs_ipc_ready; then
    log INFO "Hammerspoon IPC ready."
else
    ipc_output="$("$HS_CLI" -c "return 'ok'" 2>&1)"
    log ERROR "Hammerspoon IPC not available after waiting."
    [[ -n "$ipc_output" ]] && log ERROR "Last IPC error: $ipc_output"
    exit_or_return 1
fi

# Apply layout
log INFO "Applying window layout via Hammerspoon..."
if ! apply_output="$("$HS_CLI" -c "applyWorkspace()" 2>&1)"; then
    log ERROR "Failed to apply Hammerspoon workspace layout."
    [[ -n "$apply_output" ]] && log ERROR "Hammerspoon output: $apply_output"
    exit_or_return 1
fi

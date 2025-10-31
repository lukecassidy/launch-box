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

source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

log INFO "Layout plugin running..."

# Hammerspoon CLI location
HS_CLI="/opt/homebrew/bin/hs"

# Check dependencies and skip if missing
if ! is_cmd_installed "/opt/homebrew/bin/lua"; then
    log ERROR "Skipping layout: lua not installed"
    exit_or_return 0
fi
if ! is_app_installed "Hammerspoon"; then
    log ERROR "Skipping layout: Hammerspoon not installed"
    exit_or_return 0
fi

# Ensure Hammerspoon config symlink exists
repo_cfg="$(dirname "${BASH_SOURCE[0]}")/hammerspoon.lua"
target_cfg="$HOME/.hammerspoon/init.lua"

if [[ "$(readlink "$target_cfg")" != "$(realpath "$repo_cfg")" ]]; then
    log INFO "Linking Hammerspoon config → $target_cfg"
    mkdir -p "$(dirname "$target_cfg")"
    ln -sf "$(realpath "$repo_cfg")" "$target_cfg"
else
    log INFO "Hammerspoon config link already correct."
fi

# Ensure Hammerspoon is running
if ! pgrep -x "Hammerspoon" >/dev/null; then
    log INFO "Starting Hammerspoon..."
    gui_open -a Hammerspoon
    sleep 2
fi

# Wait for Hammerspoon IPC to become available
log INFO "Waiting for Hammerspoon IPC to become available..."
ipc_status=0
ipc_output=""
for attempt in {1..5}; do
    if ipc_output="$(gui_run "$HS_CLI" -c "return 'ok'" 2>&1)"; then
        log INFO "Hammerspoon IPC ready (attempt $attempt)."
        break
    fi
    ipc_status=$?
    if (( attempt == 5 )); then
        log ERROR "Hammerspoon IPC not available after ${attempt} attempts."
        exit_or_return 1
    fi
    log WARN "Hammerspoon IPC not ready (attempt $attempt/5). Retrying..."
    sleep 1
done

# Apply layout
log INFO "Applying window layout via Hammerspoon..."
if ! apply_output="$(gui_run "$HS_CLI" -c "applyWorkspace()" 2>&1)"; then
    apply_status=$?
    log ERROR "Failed to apply Hammerspoon workspace layout."
    exit_or_return 1
fi

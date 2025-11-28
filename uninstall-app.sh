#!/bin/bash

###############################################################################
# LaunchBox App Uninstaller
#
# This script removes LaunchBox.app from /Applications
###############################################################################

set -e

INSTALL_DIR="/Applications"
CONFIG_DIR="$HOME/.launch-box"

echo "LaunchBox App Uninstaller"
echo "========================="
echo ""

# check if app is installed
if [[ ! -d "${INSTALL_DIR}/LaunchBox.app" ]]; then
    echo "LaunchBox.app is not installed in /Applications"
    exit 0
fi

# confirm uninstallation
read -p "Remove LaunchBox.app from /Applications? (y/N) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Uninstallation cancelled."
    exit 0
fi

# remove app
echo "Removing LaunchBox.app from /Applications..."
rm -rf "${INSTALL_DIR}/LaunchBox.app"

echo "LaunchBox.app has been removed"
echo ""

# ask about config
if [[ -d "$CONFIG_DIR" ]]; then
    read -p "Remove config and logs at ~/.launch-box/? (y/N) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$CONFIG_DIR"
        echo "Config and logs removed"
    else
        echo "Config and logs kept at: ~/.launch-box/"
    fi
fi

echo ""
echo "Uninstallation complete!"

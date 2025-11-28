#!/bin/bash

###############################################################################
# LaunchBox App Installer
#
# This script installs LaunchBox.app to /Applications so it can:
# - Appear in Launchpad
# - Request its own Accessibility permissions
# - Be added to Login Items
###############################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_BUNDLE="${SCRIPT_DIR}/app-bundle/LaunchBox.app"
INSTALL_DIR="/Applications"
RESOURCES_DIR="${INSTALL_DIR}/LaunchBox.app/Contents/Resources"

echo "LaunchBox App Installer"
echo "======================="
echo ""

# check if app bundle exists
if [[ ! -d "$APP_BUNDLE" ]]; then
    echo "Error: App bundle not found at: $APP_BUNDLE"
    echo "Please ensure the app-bundle directory exists."
    exit 1
fi

# check if already installed
if [[ -d "${INSTALL_DIR}/LaunchBox.app" ]]; then
    echo "LaunchBox.app is already installed in /Applications"
    read -p "Do you want to reinstall? (y/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 0
    fi
    echo "Removing existing installation..."
    rm -rf "${INSTALL_DIR}/LaunchBox.app"
fi

# copy app to Applications
echo "Installing LaunchBox.app to /Applications..."
cp -R "$APP_BUNDLE" "$INSTALL_DIR/"

# copy the launch-box scripts and dependencies into the app bundle
echo "Copying launch-box scripts into app bundle..."
mkdir -p "$RESOURCES_DIR"
cp "${SCRIPT_DIR}/launch-box.sh" "$RESOURCES_DIR/"
cp "${SCRIPT_DIR}/launch-config.example.json" "$RESOURCES_DIR/"
cp -R "${SCRIPT_DIR}/plugins" "$RESOURCES_DIR/"
cp -R "${SCRIPT_DIR}/lib" "$RESOURCES_DIR/"
cp -R "${SCRIPT_DIR}/layout" "$RESOURCES_DIR/"

# make sure scripts are executable
chmod +x "${INSTALL_DIR}/LaunchBox.app/Contents/MacOS/launch-box"
chmod +x "$RESOURCES_DIR/launch-box.sh"
chmod +x "$RESOURCES_DIR/plugins/"*.sh
chmod +x "$RESOURCES_DIR/layout/"*.sh

echo ""
echo "✓ Installation complete!"
echo ""
echo "Next steps:"
echo "  1. Open /Applications/LaunchBox.app)"
echo "  2. Grant Accessibility: System Settings → Privacy & Security → Accessibility → Add LaunchBox"
echo "  3. Customise config: open ~/.launch-box"
echo ""
echo "Your config and logs are at: ~/.launch-box/"

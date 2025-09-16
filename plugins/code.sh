#!/bin/bash

echo "Merging all Visual Studio Code 'mac' windows..."

# Merge all Visual Studio Code windows
osascript <<'EOF'
tell application "System Events"
    tell process "Code"
        set frontmost to true
        try
            click menu item "Merge All Windows" of menu "Window" of menu bar 1
        on error
            display notification "Couldn't merge windows. " with title "Visual Studio Code"
        end try
    end tell
end tell
EOF

echo "Requested VS Code to merge all windows."

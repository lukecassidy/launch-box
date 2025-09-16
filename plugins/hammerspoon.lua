-- Requirements:
--   brew install --cask hammerspoon
--   open /Applications/Hammerspoon.app
--   Enable Accessibility permissions for Hammerspoon in:
--       System Preferences > Security & Privacy > Privacy > Accessibility
--   Place this file in ~/.hammerspoon/init.lua
--   Trigger via hotkey or from a (TODO) shell script (layout.sh)
-- TODO: work with different screen numbers / arrangements
-- TODO: symlink from plugins/hammerspoon.lua to ~/.hammerspoon/init.lua

hs.ipc.cliInstall()

-- Layout config
local workspace = {
    -- Get exact names using `hs.screen.allScreens()`
    -- TODO: give friendly names to screens
    ["Built-in Retina Display"] = {
        { app = "Slack",   slot = "left" },
        { app = "Spotify", slot = "right" },
    },
    ["LS27D60xU (1)"] = {
        { app = "Google Chrome", slot = "left" },
        { app = "code",          slot = "right" },
    },
    ["LS27D60xU (2)"] = {
        { app = "iTerm",   slot = "left" },
        { app = "ChatGPT", slot = "tr" },
        { app = "Notion",  slot = "br" },
    },
}

-- Screen mapper
local function getScreens()
    local map = {}
    for _, s in ipairs(hs.screen.allScreens()) do
        map[s:name()] = s
    end
    return map
end

-- Presets for window positions
local rects = {
    left  = hs.geometry.rect(0, 0,   0.5, 1),
    right = hs.geometry.rect(0.5, 0, 0.5, 1),
    tl    = hs.geometry.rect(0, 0,   0.5, 0.5),
    tr    = hs.geometry.rect(0.5, 0, 0.5, 0.5),
    bl    = hs.geometry.rect(0, 0.5, 0.5, 0.5),
    br    = hs.geometry.rect(0.5, 0.5, 0.5, 0.5),
}

-- Window mover - Finds app, launches if needed, moves/resizes
local function moveApp(appName, screen, slot)
    if not screen then
        hs.alert.show("Missing screen for " .. appName)
        return
    end

    local rect = rects[slot]
    if not rect then
        hs.alert.show("Unknown slot: " .. tostring(slot))
        return
    end

    -- Launch the app if not already running
    local app = hs.application.find(appName)
    if not app or not app:mainWindow() then
        hs.application.launchOrFocus(appName)
        hs.timer.doAfter(2, function()
            moveApp(appName, screen, slot)
        end)
        return
    end

    local win = app:mainWindow()
    if not win then
        hs.alert.show("No window found for " .. appName)
        return
    end

    if win:isFullScreen() then win:setFullScreen(false) end
    win:moveToScreen(screen)
    win:moveToUnit(rect)

    -- Debug output to console
    hs.printf("Moved %s -> %s:%s", appName, screen:name(), slot)
end

-- Place each window defined for a screen
local function placeWindows(screen, layout)
    for _, item in ipairs(layout) do
        moveApp(item.app, screen, item.slot)
    end
end

-- Apply the configured workspace
function applyWorkspace()
    local screens = getScreens()
    for screenName, layout in pairs(workspace) do
        local screen = screens[screenName]
        placeWindows(screen, layout)
    end
    hs.alert.show("Layout applied")
end

-- Trigger via hotkey (cmd+alt+ctrl+L) or from shell script
hs.hotkey.bind({"cmd","alt","ctrl"}, "L", applyWorkspace)

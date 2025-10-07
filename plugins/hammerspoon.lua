-- Requirements:
--   brew install --cask hammerspoon
--   open /Applications/Hammerspoon.app
--   Enable Accessibility permissions for Hammerspoon in:
--       System Preferences > Security & Privacy > Privacy > Accessibility
-- TODO: symlink from plugins/hammerspoon.lua to ~/.hammerspoon/init.lua

hs.ipc.cliInstall()

-- Layouts for different monitor setups
local layouts = {

    -- Single-monitor (laptop only)
    single = {
        ["Built-in Retina Display"] = {
            { app = "code",          slot = "left" },
            { app = "Google Chrome", slot = "tr" },
            { app = "iTerm",         slot = "br" },
        },
    },

    -- Dual-monitor (laptop + one external)
    dual = {
        ["Built-in Retina Display"] = {
            { app = "Slack",   slot = "left" },
            { app = "Spotify", slot = "tr" },
            { app = "iTerm",   slot = "br" },
        },
        ["LS27D60xU"] = {
            { app = "code",          slot = "left" },
            { app = "Google Chrome", slot = "right" },
        },
    },

    -- Triple-monitor (laptop + two externals)
    triple = {
        ["Built-in Retina Display"] = {
            { app = "Slack",   slot = "left" },
            { app = "Spotify", slot = "right" },
        },
        ["LS27D60xU (1)"] = {
            { app = "code",          slot = "left" },
            { app = "Google Chrome", slot = "right" },
        },
        ["LS27D60xU (2)"] = {
            { app = "iTerm",   slot = "left" },
            { app = "ChatGPT", slot = "tr" },
            { app = "Notion",  slot = "br" },
        },
    },
}

-- Presets for window positions
local rects = {
    left  = hs.geometry.rect(0, 0,   0.5, 1),
    right = hs.geometry.rect(0.5, 0, 0.5, 1),
    tl    = hs.geometry.rect(0, 0,   0.5, 0.5),
    tr    = hs.geometry.rect(0.5, 0, 0.5, 0.5),
    bl    = hs.geometry.rect(0, 0.5, 0.5, 0.5),
    br    = hs.geometry.rect(0.5, 0.5, 0.5, 0.5),
}

-- Screen mapper
local function getScreens()
    local map = {}
    for _, s in ipairs(hs.screen.allScreens()) do
        map[s:name()] = s
    end
    return map
end

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

-- Apply the configured workspace.
function applyWorkspace(screenMode)
    local screens = getScreens()
    local screenCount = #hs.screen.allScreens()

    -- Auto-detect layout mode based on number of screens if not provided
    screenMode = screenMode or ({ [2]="dual", [3]="triple" })[screenCount] or "single"

    for screenName, layout in pairs(layouts[screenMode]) do
        local screen = screens[screenName]
        placeWindows(screen, layout)
    end
    hs.alert.show("Layout applied")
end

-- Trigger via hotkey (cmd+alt+ctrl+L) or from shell script
hs.hotkey.bind({"cmd","alt","ctrl"}, "L", function() applyWorkspace() end)

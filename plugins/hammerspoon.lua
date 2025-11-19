-- Requirements:
--   brew install --cask hammerspoon
--   open /Applications/Hammerspoon.app
--   Enable Accessibility permissions for Hammerspoon in:
--       System Preferences > Security & Privacy > Privacy > Accessibility
hs.ipc.cliInstall()

-- Load layouts from symlinkedconfig file
-- hs.configdir gives us ~/.hammerspoon
local configPath = hs.configdir .. "/plugins/launch-box-config.json"

-- Load layout definitions from config
local layouts = {}
local file = io.open(configPath, "r")
if file then
    local content = file:read("*all")
    file:close()
    local config = hs.json.decode(content)
    if config and config.layouts then
        layouts = config.layouts
    else
        hs.printf("No layouts found in config: %s", configPath)
    end
else
    hs.printf("Failed to load config from: %s", configPath)
end

-- Presets for window positions
local rects = {
    -- Halves
    lft_half_all = hs.geometry.rect(0,   0,   0.5, 1),
    rgt_half_all = hs.geometry.rect(0.5, 0,   0.5, 1),

    -- Quarters
    lft_qrtr_top = hs.geometry.rect(0,   0,   0.5, 0.5),
    lft_qrtr_bot = hs.geometry.rect(0,   0.5, 0.5, 0.5),
    rgt_qrtr_top = hs.geometry.rect(0.5, 0,   0.5, 0.5),
    rgt_qrtr_bot = hs.geometry.rect(0.5, 0.5, 0.5, 0.5),

    -- Right-side thirds
    rgt_thrd_top = hs.geometry.rect(0.5, 0,     0.5, 1/3),
    rgt_thrd_mid = hs.geometry.rect(0.5, 1/3,   0.5, 1/3),
    rgt_thrd_bot = hs.geometry.rect(0.5, 2/3,   0.5, 1/3),
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
    win:moveToUnit(rect, screen:fullFrame()) -- includes menu bar area

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
    local screenCount = #hs.screen.allScreens()

    -- Auto-detect layout mode based on number of screens if not provided
    screenMode = screenMode or ({ [2]="dual", [3]="triple" })[screenCount] or "single"

    -- Check if layouts are loaded
    if not layouts or not layouts[screenMode] then
        hs.alert.show("No layout configuration found for: " .. screenMode)
        hs.printf("Layouts table: %s", layouts and "exists" or "nil")
        hs.printf("Available modes: %s", layouts and table.concat((function() local t={} for k in pairs(layouts) do table.insert(t,k) end return t end)(), ", ") or "none")
        return
    end

    -- Get available screens by name
    local availableScreens = getScreens()

    -- Apply layout using static screen names defined in config
    for screenName, layout in pairs(layouts[screenMode]) do
        local screen = availableScreens[screenName]
        if screen then
            placeWindows(screen, layout)
        else
            hs.alert.show("Screen not found: " .. screenName)
        end
    end

    hs.alert.show("Layout applied: " .. screenMode .. " (" .. screenCount .. " screens)")
end

-- Trigger via hotkey (cmd+alt+ctrl+L) or from shell script
hs.hotkey.bind({"cmd","alt","ctrl"}, "L", function() applyWorkspace() end)
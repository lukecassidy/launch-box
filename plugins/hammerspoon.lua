-- Requirements:
--   brew install --cask hammerspoon
--   open /Applications/Hammerspoon.app
--   Enable Accessibility permissions for Hammerspoon in:
--       System Preferences > Security & Privacy > Privacy > Accessibility
hs.ipc.cliInstall()

-- Layouts for different monitor setups
local layouts = {

    -- Single-monitor (laptop only)
    single = {
        [1] = {  -- Primary screen (built-in display)
            { slot = "lft_half_all", app = "code" },
            { slot = "rgt_thrd_top", app = "Slack" },
            { slot = "rgt_thrd_mid", app = "iTerm" },
            { slot = "rgt_thrd_bot", app = "Google Chrome" },
        },
    },

    -- Dual-monitor (laptop + one external)
    dual = {
        [1] = {  -- Primary screen (built-in display)
            { slot = "lft_half_all", app = "Slack" },
            { slot = "rgt_qrtr_top", app = "Spotify" },
            { slot = "rgt_qrtr_bot", app = "iTerm" },
        },
        [2] = {  -- First external monitor
            { slot = "lft_half_all", app = "code" },
            { slot = "rgt_half_all", app = "Google Chrome" },
        },
    },

    -- Triple-monitor (laptop + two externals)
    triple = {
        [1] = {  -- Primary screen (built-in display)
            { slot = "lft_half_all", app = "Slack" },
            { slot = "rgt_half_all", app = "Spotify" },
        },
        [2] = {  -- First external monitor
            { slot = "lft_half_all", app = "code" },
            { slot = "rgt_half_all", app = "Google Chrome" },
        },
        [3] = {  -- Second external monitor
            { slot = "lft_half_all", app = "iTerm" },
            { slot = "rgt_qrtr_top", app = "ChatGPT" },
            { slot = "rgt_qrtr_bot", app = "Notion" },
        },
    },
}

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
    local allScreens = hs.screen.allScreens()
    local screenCount = #allScreens

    -- Ensure primary screen is always first
    local orderedScreens = { hs.screen.primaryScreen() }
    for _, screen in ipairs(allScreens) do
        if screen ~= orderedScreens[1] then
            table.insert(orderedScreens, screen)
        end
    end

    -- Auto-detect layout mode based on number of screens if not provided
    screenMode = screenMode or ({ [2]="dual", [3]="triple" })[screenCount] or "single"

    for screenIndex, layout in pairs(layouts[screenMode]) do
        if orderedScreens[screenIndex] then
            placeWindows(orderedScreens[screenIndex], layout)
        end
    end
    hs.alert.show("Layout applied: " .. screenMode .. " (" .. screenCount .. " screens)")
end

-- Trigger via hotkey (cmd+alt+ctrl+L) or from shell script
hs.hotkey.bind({"cmd","alt","ctrl"}, "L", function() applyWorkspace() end)

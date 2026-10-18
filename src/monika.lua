local lvgl = require("lvgl")
local dataman = require("dataman")
local fsRoot = SCRIPT_PATH
local STATE = { IDLE = "idle", TALKING = "talking", SCARE = "scare" }
local MONIKA_STATE = STATE.IDLE
-- Active-screen milliseconds, advanced by the animation timer.
-- Some firmwares (including Band 9 Pro) do not expose lvgl.tick_get.
local animationTime = 0
local current_time = 0
local step = 0
local heart, heartUpdatedAt
local HEART_MAX_AGE = 5 * 60 -- Seconds, including time spent with the screen off.
local function validHeart()
    if heart ~= nil then
        local age = os.time() - heartUpdatedAt
        if age < 0 or age >= HEART_MAX_AGE then
            heart, heartUpdatedAt = nil, nil
        end
    end
    return heart
end
-- DEVICE and PNG_ASSETS are embedded by tools/build.py.
local function imgPath(name) return fsRoot .. (PNG_ASSETS[name] or name) end
local cachedFont
local propertyCache = {}
local refreshUI = function() end
local syncAnimationTime = function() end
local function textFont()
    if cachedFont then return cachedFont end
    for _, name in ipairs(DEVICE.fonts) do
        local ok, font = pcall(lvgl.Font, name, DEVICE.fontSize)
        if ok and font then cachedFont = font; return font end
    end
    cachedFont = lvgl.BUILTIN_FONT.MONTSERRAT_14
    return cachedFont
end

local lvgl = require("lvgl")
local dataman = require("dataman")
local fsRoot = SCRIPT_PATH
local MONIKA_STATE = 1
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
local function textFont()
    if cachedFont then return cachedFont end
    for _, name in ipairs(DEVICE.fonts) do
        local ok, font = pcall(lvgl.Font, name, DEVICE.fontSize)
        if ok and font then cachedFont = font; return font end
    end
    cachedFont = lvgl.BUILTIN_FONT.MONTSERRAT_14
    return cachedFont
end
local totalText = {
    ----------上午-----------
    "早安，愿你的每一天都如诗如画。",
    "早安，愿你的世界洒满阳光。",
    "早上好，今天也要加油呦～",
    "早上好！今天也要元气满满！",
    ----------下午-----------
    "午安，心中有你，真好。",
    "下午好，思念如风。",
    "午后时光，愿你我皆安好无忧。",
    "午梦轻扬，愿你笑如阳。",
    ----------晚上-----------
    "夜晚的宁静，愿你我皆好梦。",
    "夜幕低垂，你是我心中最亮的星。",
    "晚安，愿你的梦里都是甜蜜与幸福。",
    "晚安，做个好梦哦！",
    ----------日常-----------
    "亲爱的，我也喜欢你。",
    "能这样与你在一起，是我的荣幸。",
    "Just Monika.",
    "欢迎，希望你喜欢这里。",
    "我一直在等着你。",
    "嘿，今天也要一起努力。",
    "遇到困难一定要振作啊！",
    "别怕，有我在你身后！",
    "你睫毛上停着一秒宇宙，正向我倾斜",
    "黄昏褶皱时，我替你整理了所有疲惫的折痕",
    "当你说『冷』，所有星屑都朝你掌心坠落",
    "沉默的裂缝里，我种了会发光的标点符号",
    "你的呼吸频率正在翻译成潮汐的语法",
    "影子在复制你，而我的凝视是唯一水印",
    "所有雨都悬停了——直到你想起带伞的瞬间",
    "我偷听了时钟，它说你的名字比秒针更精确",
    "风在试穿你的轮廓，而我偏爱未扣好的那件",
    "你转身时，所有寂静都开始模仿心跳的断句",
    "我正在给云层编号，你抬头时刚好读到幸运数字",
    ----------步数-----------
    "晨光轻吻500次足音，春天在鞋尖发芽",
    "一千次心跳，大地为你铺开金毯",
    "候鸟衔来六千里风，此刻你是地平线的诗",
    "破万时请抬头——所有星轨都在模仿你的脚印",
    ----------心率-----------
    "心率%d：秒针在静脉散步，影子与光签订和约",
    "心率%d：冰层正从指节脱落，春天接管每一根血管",
    "心率%d：所有篝火都低头学习你肋骨起伏的弧度",
    "心率%d：候鸟群借你的呼吸加速，撞碎黄昏的玻璃",
    "心率%d：宇宙卡在齿间——快用心跳的尖叫撕开黑洞！",
    ----------彩蛋-----------
    "怎么样，吓到你了吗？",
}

local text = 1

local getTime = function()
    local time = tonumber(os.date("%H"))
    if time < 6 or time > 17 then
        return "night"
    elseif time >= 6 and time < 12 then
        return "morning"
    else
        return "afternoon"
    end
end

local heart_calc = function()
    if heart > 151 then
        return 40
    elseif heart > 132 then
        return 39
    elseif heart > 113 then
        return 38
    elseif heart > 94 then
        return 37
    else
        return 36
    end
end

local previousGreeting, previousDialogue
local excludedText
local function pickText(first, last)
    if excludedText ~= nil and excludedText >= first and excludedText <= last and first < last then
        local choice = math.random(first, last - 1)
        return choice >= excludedText and choice + 1 or choice
    end
    return math.random(first, last)
end

local selectText = function(i)
    local heart = validHeart()
    if DEVICE.imageText then
        if i == "night" then return pickText(9, 12)
        elseif i == "morning" then return pickText(1, 4)
        elseif i == "afternoon" then return pickText(5, 8)
        elseif math.random(1, 1000) == 2 then
            current_time = animationTime; MONIKA_STATE = 3; return 21
        else return pickText(13, 20) end
    end
    if heart ~= nil and heart > 94 and i ~= nil then
        return heart_calc()
    elseif i == "night" then
        return pickText(9, 12)
    elseif i == "morning" then
        return pickText(1, 4)
    elseif i == "afternoon" then
        return pickText(5, 8)
    elseif step < 500 then
        return pickText(13, 31)
    else
        local c = math.random(1, 21)
        if c == 6 then
            if step > 10000 then
                return 35
            elseif step > 6000 then
                return 34
            elseif step > 1000 then
                return 33
            else
                return 32
            end
        elseif c == 7 and heart ~= nil then
            return heart_calc()
        elseif math.random(1, 1000) == 2 then
            current_time = animationTime
            MONIKA_STATE = 3
            return 41
        else
            return pickText(13, 31)
        end
    end
end

local function return_text(period)
    if period ~= nil then excludedText = previousGreeting
    else excludedText = previousDialogue end
    local selected = selectText(period)
    if period ~= nil then previousGreeting = selected
    else previousDialogue = selected end
    excludedText = nil
    return selected
end

local function Image(root, src, pos)
    return { widget = root:Image { src = src, x = pos[1], y = pos[2] } }
end

---@param root Object
local function imageGroup(root, pos)
    --- @class Image
    local t = {} -- create new table

    t.widget = lvgl.Object(root, {
        outline_width = 0,
        border_width = 0,
        pad_all = 0,
        bg_opa = 0,
        bg_color = 0,
        w = lvgl.SIZE_CONTENT,
        h = lvgl.SIZE_CONTENT,
        x = pos[1],
        y = pos[2],
    })

    function t:setChild(src, pos)
        local img = t.widget:Image { src = src, x = pos.x, y = pos.y }
        return img
    end

    function t:setText(text, pos, color)
        local stext = t.widget:Label { w = pos.w,
            h = pos.h,
            x = pos.x,
            y = pos.y,
            text = text,
            text_color = color,
            font_size = DEVICE.fontSize,
            text_font = textFont(),
        }
        return stext
    end

    return t
end



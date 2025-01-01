local lvgl = require("lvgl")
local dataman = require("dataman")

local fsRoot = SCRIPT_PATH
local DEBUG_ENABLE = false

local STATE_POSITION_UP = 1
local STATE_POSITION_MID = 2
local STATE_POSITION_BOTTOM = 3

local MONIKA_STATE = 1
local current_time
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

local return_text = function(i)
    if i == "night" then
        return math.random(9, 12)
    elseif i == "morning" then
        return math.random(1, 4)
    elseif i == "afternoon" then
        return math.random(5, 8)
    elseif math.random(1, 1000) == 2 then
        current_time = os.clock()
        MONIKA_STATE = 3
        return 21
    else
        return math.random(13, 20)
    end
end

local if_dark = function(i, n)
    if getTime() == "night" then
        return i .. "_n" .. n
    else
        return i .. n
    end
end

local printf = DEBUG_ENABLE and print or function(...)
end

function imgPath(src)
    return fsRoot .. src
end

-- Create an image to support state amim etc.
---@param root Object
---@return Image
local function Image(root, src, pos)
    --- @class Image
    local t = {} -- create new table

    t.widget = root:Image { src = src }
    local w, h = t.widget:get_img_size()
    t.w = w
    t.h = h

    -- current state, center
    t.pos = {
        x = pos[1],
        y = pos[2]
    }

    function t:getImageWidth()
        return t.w
    end

    function t:getImageheight()
        return t.h
    end

    t.defaultY = pos[2]
    t.lastState = STATE_POSITION_MID
    t.state = STATE_POSITION_MID

    t.widget:set {
        w = w,
        h = h,
        x = t.pos.x,
        y = t.pos.y
    }

    -- create animation and put it on hold
    local anim = t.widget:Anim {
        run = false,
        start_value = 0,
        end_value = 1000,
        time = 560, -- 560ms fixed
        repeat_count = 1,
        path = "ease_in_out",
        exec_cb = function(obj, now)
            obj:set { y = now }
            t.pos.y = now
        end
    }

    t.posAnim = anim

    return t
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
        x = pos.x,
        y = pos.y,
    })

    function t:setChild(src, pos)
        local img = t.widget:Image { src = src, x = pos.x, y = pos.y }
        return img
    end

    local function fileExists(name)
        local f = io.open(name, "r")
        if f ~= nil then
            io.close(f)
            return true
        else
            return false
        end
    end

    local isS3 = fileExists('/font/MiSans-Demibold.ttf') or fileExists('/system/font/MiSans-Demibold.ttf')

    local TEXT_FONT = lvgl.BUILTIN_FONT.MONTSERRAT_14

    function FontChange(font1, font2)
        if DEBUG_ENABLE == false then
            if isS3 then
                TEXT_FONT = lvgl.Font('MiSans-' .. font2 .. '', 16)
            else
                TEXT_FONT = lvgl.Font('misansw_' .. font1 .. '', 16)
            end
        end
    end

    FontChange("demibold", "Demibold")

    function t:setText(text, pos, color)
        local stext = t.widget:Label { w = pos.w,
            h = pos.h,
            x = pos.x,
            y = pos.y,
            text = text,
            text_color = color,
            font_size = 16,
            text_font = TEXT_FONT,
        }
        return stext
    end

    -- current state, center
    t.pos = {
        x = pos[1],
        y = pos[2]
    }

    t.defaultY = pos[2]
    t.lastState = STATE_POSITION_MID
    t.state = STATE_POSITION_MID

    t.widget:set {
        x = t.pos.x,
        y = t.pos.y
    }

    function t:getChildCnt()
        return t.widget:get_child_cnt()
    end

    function t:getChild(i)
        return t.widget:get_child(i)
    end

    function t:getParent()
        return t.widget:get_parent()
    end

    -- create animation and put it on hold
    local anim = t.widget:Anim {
        run = false,
        start_value = 0,
        end_value = 1000,
        time = 560, -- 560ms fixed
        repeat_count = 1,
        path = "ease_in_out",
        exec_cb = function(obj, now)
            obj:set { y = now }
            t.pos.y = now
        end
    }

    t.posAnim = anim

    return t
end


---@param parent Object
local function createWatchface(parent)
    local t = {}

    local wfRoot = lvgl.Object(parent, {
        outline_width = 0,
        border_width = 0,
        pad_all = 0,
        bg_opa = 0,
        bg_color = 0,
        align = lvgl.ALIGN.CENTER,
        w = 336,
        h = 480,
    })
    wfRoot:clear_flag(lvgl.FLAG.SCROLLABLE)
    wfRoot:add_flag(lvgl.FLAG.EVENT_BUBBLE)

    -- 背景
    t.objImage = lvgl.Image(wfRoot, { x = 0, y = 0, src = imgPath("bg.bin") })

    -- 电池电量
    t.chargeCont = imageGroup(wfRoot, { 0, 453 })
    t.chargeImg = t.chargeCont:setChild(imgPath("ap.bin"), { x = 126, y = 1 }) -- 充电图标
    t.chargeContChild1 = t.chargeCont:setChild(imgPath("num1.bin"), { x = 149 });
    t.chargeContChild2 = t.chargeCont:setChild(imgPath("num0.bin"), { x = 162 });
    t.chargeContChild3 = t.chargeCont:setChild(imgPath("num0.bin"), { x = 174 });
    t.chargeContChild4 = t.chargeCont:setChild(imgPath("num%.bin"), { x = 190 });

    -- 小时分钟
    t.time = imageGroup(wfRoot, { 0, 297 })
    t.timeHourHigh = t.time:setChild(imgPath("0.bin"), { x = 43 })
    t.timeHourLow = t.time:setChild(imgPath("0.bin"), { x = 97 })
    t.timeGang = t.time:setChild(imgPath("num_mao.bin"), { x = 141, y = -3 })
    t.timeMinuteHigh = t.time:setChild(imgPath("0.bin"), { x = 185 })
    t.timeMinuteLow = t.time:setChild(imgPath("0.bin"), { x = 239 })

    -- 日期
    t.dateCont = imageGroup(wfRoot, { 0, 365 })
    t.dateContChild1 = t.dateCont:setChild(imgPath("num0.bin"), { x = 93 });
    t.dateContChild2 = t.dateCont:setChild(imgPath("num8.bin"), { x = 105 });
    t.dateContChild3 = t.dateCont:setChild(imgPath("num_gang.bin"), { x = 115 });
    t.dateContChild4 = t.dateCont:setChild(imgPath("num1.bin"), { x = 125 });
    t.dateContChild5 = t.dateCont:setChild(imgPath("num6.bin"), { x = 136 });

    -- 星期
    t.dateWeek = t.dateCont:setChild(imgPath("mon.bin"), { x = 188, y = 2 })

    t.monikaEye = Image(wfRoot, imgPath("eye_close.bin"), { 0, 92 })

    t.msg = imageGroup(wfRoot, { 0, 345 })
    t.msgBox = t.msg:setChild(imgPath("msg.bin"), { x = 18, y = 0 })

    t.text9 = t.msg:setText("", { w = 280, h = 47, x = 12, y = 25 }, "#000000")
    t.text8 = t.msg:setText("", { w = 280, h = 47, x = 12, y = 27 }, "#000000")
    t.text7 = t.msg:setText("", { w = 280, h = 47, x = 14, y = 25 }, "#000000")
    t.text6 = t.msg:setText("", { w = 280, h = 47, x = 14, y = 27 }, "#000000")
    t.text5 = t.msg:setText("", { w = 280, h = 47, x = 13, y = 27 }, "#000000")
    t.text4 = t.msg:setText("", { w = 280, h = 47, x = 13, y = 25 }, "#000000")
    t.text3 = t.msg:setText("", { w = 280, h = 47, x = 12, y = 26 }, "#000000")
    t.text2 = t.msg:setText("", { w = 280, h = 47, x = 14, y = 26 }, "#000000")
    t.text = t.msg:setText("", { w = 280, h = 47, x = 13, y = 26 }, "#ffffff")

    wfRoot:onevent(lvgl.EVENT.SHORT_CLICKED, function(obj, code)
        local indev = lvgl.indev.get_act()
        local x, y = indev:get_point()
        if (y <= 225 and MONIKA_STATE ~= 3) then
            MONIKA_STATE = 2
            text = return_text()
            current_time = os.clock()
        end
    end)

    t.msg.widget:onevent(lvgl.EVENT.SHORT_CLICKED, function(obj, code)
        local indev = lvgl.indev.get_act()
        local x, y = indev:get_point()
        if (MONIKA_STATE ~= 1) then
            MONIKA_STATE = 1
            current_time = os.clock()
        end
    end)

    return t
end

local function uiCreate()
    local root = lvgl.Object(nil, {
        w = lvgl.HOR_RES(),
        h = lvgl.VER_RES(),
        bg_color = 0,
        bg_opa = lvgl.OPA(100),
        border_width = 0,
    })
    root:clear_flag(lvgl.FLAG.SCROLLABLE)
    root:add_flag(lvgl.FLAG.EVENT_BUBBLE)

    local watchface = createWatchface(root)

    local function screenONCb()
        -- printf("screen on")
        text = return_text(getTime())
        MONIKA_STATE = 2
        current_time = os.clock()
    end

    local function screenOFFCb()
        --printf("screen off")
    end

    screenONCb() -- screen is ON when watchface created

    local eye_time = math.random(7, 10)

    watchface.msg.widget:add_flag(lvgl.FLAG.HIDDEN)

    dataman.subscribe("timeCentiSecond", watchface.monikaEye.widget, function(obj, value)
        target_time = os.clock()
        if MONIKA_STATE ~= 3 then
            watchface.objImage:set({ src = imgPath(if_dark("bg", ".bin")) })
        end
        if MONIKA_STATE == 2 then
            watchface.monikaEye.widget:add_flag(lvgl.FLAG.HIDDEN)
            watchface.monikaEye.widget:set({ src = imgPath(if_dark("smile", ".bin")) })
            watchface.time.widget:set({ y = 245 })
            watchface.dateCont.widget:set({ y = 313 })
            watchface.text:set({ text = totalText[text] })
            watchface.text2:set({ text = totalText[text] })
            watchface.text3:set({ text = totalText[text] })
            watchface.text4:set({ text = totalText[text] })
            watchface.text5:set({ text = totalText[text] })
            watchface.text6:set({ text = totalText[text] })
            watchface.text7:set({ text = totalText[text] })
            watchface.text8:set({ text = totalText[text] })
            watchface.text9:set({ text = totalText[text] })
            watchface.monikaEye.widget:clear_flag(lvgl.FLAG.HIDDEN)
            watchface.msg.widget:clear_flag(lvgl.FLAG.HIDDEN)
            if current_time + 3 <= target_time then
                MONIKA_STATE = 1
                current_time = os.clock()
            end
        elseif MONIKA_STATE == 3 then
            watchface.time.widget:add_flag(lvgl.FLAG.HIDDEN)
            watchface.dateCont.widget:add_flag(lvgl.FLAG.HIDDEN)
            watchface.chargeCont.widget:add_flag(lvgl.FLAG.HIDDEN)
            watchface.monikaEye.widget:add_flag(lvgl.FLAG.HIDDEN)
            watchface.msg.widget:add_flag(lvgl.FLAG.HIDDEN)
            watchface.objImage:set({ src = imgPath("scare.bin") })
            if current_time + 1 <= target_time then
                watchface.time.widget:clear_flag(lvgl.FLAG.HIDDEN)
                watchface.dateCont.widget:clear_flag(lvgl.FLAG.HIDDEN)
                watchface.chargeCont.widget:clear_flag(lvgl.FLAG.HIDDEN)
                watchface.monikaEye.widget:clear_flag(lvgl.FLAG.HIDDEN)
                watchface.msg.widget:clear_flag(lvgl.FLAG.HIDDEN)
                text = 15
                MONIKA_STATE = 2
                current_time = os.clock()
            end
        else
            watchface.time.widget:set({ y = 297 })
            watchface.dateCont.widget:set({ y = 365 })
            watchface.msg.widget:add_flag(lvgl.FLAG.HIDDEN)
            if current_time + eye_time <= target_time then
                watchface.monikaEye.widget:set({ src = imgPath(if_dark("eye_close", ".bin")) })
                watchface.monikaEye.widget:clear_flag(lvgl.FLAG.HIDDEN)
                if current_time + eye_time <= target_time - 0.4 then
                    watchface.monikaEye.widget:add_flag(lvgl.FLAG.HIDDEN)
                    current_time = os.clock()
                    eye_time = math.random(7, 10)
                end
            else
                watchface.monikaEye.widget:add_flag(lvgl.FLAG.HIDDEN)
            end
        end
    end)

    -- 电池电量
    dataman.subscribe("systemStatusBattery", watchface.chargeCont.widget, function(obj, value)
        local index = value // 256
        watchface.chargeContChild1:add_flag(lvgl.FLAG.HIDDEN)
        watchface.chargeContChild2:add_flag(lvgl.FLAG.HIDDEN)
        watchface.chargeContChild3:add_flag(lvgl.FLAG.HIDDEN)
        watchface.chargeContChild4:add_flag(lvgl.FLAG.HIDDEN)

        local s = 1
        if index < 10 then
            src = string.format("num%d.bin", index)
            watchface.chargeImg:set({ x = 138 })
            watchface.chargeContChild1:set({ src = imgPath(src), x = 162 })
            watchface.chargeContChild1:clear_flag(lvgl.FLAG.HIDDEN)
            watchface.chargeContChild2:set({ src = imgPath("num%.bin"), x = 178 })
            watchface.chargeContChild2:clear_flag(lvgl.FLAG.HIDDEN)
        elseif index < 100 then
            watchface.chargeImg:set({ x = 133 })
            src = string.format("num%d.bin", index // 10)
            watchface.chargeContChild1:set({ src = imgPath(src), x = 159 })
            watchface.chargeContChild1:clear_flag(lvgl.FLAG.HIDDEN)
            src = string.format("num%d.bin", index % 10)
            watchface.chargeContChild2:set({ src = imgPath(src), x = 171 })
            watchface.chargeContChild2:clear_flag(lvgl.FLAG.HIDDEN)
            watchface.chargeContChild3:set({ src = imgPath("num%.bin"), x = 187 })
            watchface.chargeContChild3:clear_flag(lvgl.FLAG.HIDDEN)
            s = 2
        else
            watchface.chargeImg:set({ x = 126 })
            src = string.format("num%d.bin", 1)
            watchface.chargeContChild1:set({ src = imgPath(src), x = 149 })
            watchface.chargeContChild1:clear_flag(lvgl.FLAG.HIDDEN)
            src = string.format("num%d.bin", 0)
            watchface.chargeContChild2:set({ src = imgPath(src), x = 163 })
            watchface.chargeContChild2:clear_flag(lvgl.FLAG.HIDDEN)
            src = string.format("num%d.bin", 0)
            watchface.chargeContChild3:set({ src = imgPath(src), x = 174 })
            watchface.chargeContChild3:clear_flag(lvgl.FLAG.HIDDEN)
            watchface.chargeContChild4:set({ src = imgPath("num%.bin"), x = 190 })
            watchface.chargeContChild4:clear_flag(lvgl.FLAG.HIDDEN)
            s = 3
        end
    end)

    -- 小时分钟
    dataman.subscribe("timeHourHigh", watchface.time.widget:get_child(0), function(obj, value)
        src = string.format("%d.bin", value // 256)
        obj:set { src = imgPath(src) }
    end)
    dataman.subscribe("timeHourLow", watchface.time.widget:get_child(1), function(obj, value)
        src = string.format("%d.bin", value // 256)
        obj:set { src = imgPath(src) }
    end)
    dataman.subscribe("timeMinuteHigh", watchface.time.widget:get_child(3), function(obj, value)
        src = string.format("%d.bin", value // 256)
        obj:set { src = imgPath(src) }
    end)
    dataman.subscribe("timeMinuteLow", watchface.time.widget:get_child(4), function(obj, value)
        src = string.format("%d.bin", value // 256)
        obj:set { src = imgPath(src) }
    end)

    -- 星期
    dataman.subscribe("dateWeek", watchface.dateCont.widget:get_child(5), function(obj, value)
        index = value // 256
        index = index + 1
        src = { "sun", "mon", "tue", "wed", "thu", "fri", "sat" }
        str = string.format("%s.bin", src[index])
        obj:set { src = imgPath(str) }
    end)

    -- 月份
    dataman.subscribe("dateMonth", watchface.dateCont.widget, function(obj, value)
        index = value // 256
        watchface.dateContChild1:add_flag(lvgl.FLAG.HIDDEN)
        watchface.dateContChild2:add_flag(lvgl.FLAG.HIDDEN)
        if index < 10 then
            watchface.dateContChild1:set({ src = imgPath("num0.bin") });
            watchface.dateContChild1:clear_flag(lvgl.FLAG.HIDDEN)
            src = string.format("num%d.bin", index)
            watchface.dateContChild2:set({ src = imgPath(src) });
            watchface.dateContChild2:clear_flag(lvgl.FLAG.HIDDEN)
        else
            src = string.format("num%d.bin", index // 10)
            watchface.dateContChild1:set({ src = imgPath(src) });
            watchface.dateContChild1:clear_flag(lvgl.FLAG.HIDDEN)
            src = string.format("num%d.bin", index % 10)
            watchface.dateContChild2:set({ src = imgPath(src) });
            watchface.dateContChild2:clear_flag(lvgl.FLAG.HIDDEN)
        end
    end)

    -- 星期
    dataman.subscribe("dateDay", watchface.dateCont.widget, function(obj, value)
        index = value // 256
        watchface.dateContChild4:add_flag(lvgl.FLAG.HIDDEN)
        watchface.dateContChild5:add_flag(lvgl.FLAG.HIDDEN)
        if index < 10 then
            watchface.dateContChild4:set({ src = imgPath("num0.bin") });
            watchface.dateContChild4:clear_flag(lvgl.FLAG.HIDDEN)
            src = string.format("num%d.bin", index)
            watchface.dateContChild5:set({ src = imgPath(src) });
            watchface.dateContChild5:clear_flag(lvgl.FLAG.HIDDEN)
        else
            src = string.format("num%d.bin", index // 10)
            watchface.dateContChild4:set({ src = imgPath(src) });
            watchface.dateContChild4:clear_flag(lvgl.FLAG.HIDDEN)
            src = string.format("num%d.bin", index % 10)
            watchface.dateContChild5:set({ src = imgPath(src) });
            watchface.dateContChild5:clear_flag(lvgl.FLAG.HIDDEN)
        end
    end)

    return screenONCb, screenOFFCb
end

local on, off = uiCreate()

function ScreenStateChangedCB(pre, now, reason)
    --printf("screen state", pre, now, reason)
    if pre ~= "ON" and now == "ON" then
        on()
    elseif pre == "ON" and now ~= "ON" then
        off()
    end
end

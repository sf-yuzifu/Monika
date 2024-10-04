local lvgl = require("lvgl")
local dataman = require("dataman")

local fsRoot = SCRIPT_PATH
local DEBUG_ENABLE = false

local STATE_POSITION_UP = 1
local STATE_POSITION_MID = 2
local STATE_POSITION_BOTTOM = 3

local MONIKA_STATE = 1
local current_time
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
        return math.random(7, 9)
    elseif i == "morning" then
        return math.random(1, 3)
    elseif i == "afternoon" then
        return math.random(4, 6)
    elseif math.random(1, 100) == 2 then
        current_time = os.clock()
        MONIKA_STATE = 3
        return 15
    else
        return math.random(10, 14)
    end
end

local if_dark =  function (i,n)
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
        w = 192,
        h = 490,
    })
    wfRoot:clear_flag(lvgl.FLAG.SCROLLABLE)
    wfRoot:add_flag(lvgl.FLAG.EVENT_BUBBLE)

    -- 背景
    t.objImage = lvgl.Image(wfRoot, { x = 0, y = 0, src = imgPath("bg.bin") })

    -- 电池电量
    t.chargeCont = imageGroup(wfRoot, { 0, 461 })
    t.chargeImg = t.chargeCont:setChild(imgPath("ap.bin"), { x = 78, y = 1 }) -- 充电图标
    t.chargeContChild1 = t.chargeCont:setChild(imgPath("num8.bin"), { x = 78 });
    t.chargeContChild2 = t.chargeCont:setChild(imgPath("num0.bin"), { x = 91 });
    t.chargeContChild3 = t.chargeCont:setChild(imgPath("num%.bin"), { x = 103 });
    t.chargeContChild4 = t.chargeCont:setChild(imgPath("num0.bin"), { x = 119 });

    -- 小时分钟
    t.time = imageGroup(wfRoot, { 0, 294 })
    t.timeHourHigh = t.time:setChild(imgPath("0.bin"), { x = -7 })
    t.timeHourLow = t.time:setChild(imgPath("0.bin"), { x = 33 })
    t.timeGang = t.time:setChild(imgPath("num_mao.bin"), { x = 69, y = -3 })
    t.timeMinuteHigh = t.time:setChild(imgPath("0.bin"), { x = 105 })
    t.timeMinuteLow = t.time:setChild(imgPath("0.bin"), { x = 145 })

    -- 日期
    t.dateCont = imageGroup(wfRoot, { 0, 364 })
    t.dateContChild1 = t.dateCont:setChild(imgPath("num0.bin"), { x = 37 });
    t.dateContChild2 = t.dateCont:setChild(imgPath("num8.bin"), { x = 49 });
    t.dateContChild3 = t.dateCont:setChild(imgPath("num_gang.bin"), { x = 59 });
    t.dateContChild4 = t.dateCont:setChild(imgPath("num1.bin"), { x = 69 });
    t.dateContChild5 = t.dateCont:setChild(imgPath("num6.bin"), { x = 80 });

    -- 星期
    t.dateWeek = t.dateCont:setChild(imgPath("mon.bin"), { x = 105, y = 2 })

    t.monikaEye = Image(wfRoot, imgPath("eye_close.bin"), { 0, 104 })

    t.msg = imageGroup(wfRoot, { 0, 366 })
    t.msgBox = t.msg:setChild(imgPath("msg.bin"), { x = 1, y = 0 })
    t.text = t.msg:setChild(imgPath("text1.bin"), { x = 12, y = 25 })

    wfRoot:onevent(lvgl.EVENT.SHORT_CLICKED, function(obj, code)
        local indev = lvgl.indev.get_act()
        local x, y = indev:get_point()
        if (y <= 225 and MONIKA_STATE ~= 3) then
            MONIKA_STATE = 2
            text = return_text()
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
            watchface.objImage:set({ src = imgPath(if_dark("bg",".bin")) })
        end
        if MONIKA_STATE == 2 then
            watchface.monikaEye.widget:add_flag(lvgl.FLAG.HIDDEN)
            watchface.monikaEye.widget:set({ src = imgPath(if_dark("smile",".bin")) })
            watchface.time.widget:set({ y = 267 })
            watchface.dateCont.widget:set({ y = 335 })
            watchface.text:set({ src = imgPath("text" .. text .. ".bin") })
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
            watchface.time.widget:set({ y = 294 })
            watchface.dateCont.widget:set({ y = 364 })
            watchface.msg.widget:add_flag(lvgl.FLAG.HIDDEN)
            if current_time + eye_time <= target_time then
                watchface.monikaEye.widget:set({ src = imgPath(if_dark("eye_close",".bin")) })
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
            watchface.chargeImg:set({ x = 67 })
            watchface.chargeContChild1:set({ src = imgPath(src), x = 91 })
            watchface.chargeContChild1:clear_flag(lvgl.FLAG.HIDDEN)
            watchface.chargeContChild2:set({ src = imgPath("num%.bin"), x = 107 })
            watchface.chargeContChild2:clear_flag(lvgl.FLAG.HIDDEN)
        elseif index < 100 then
            watchface.chargeImg:set({ x = 61 })
            src = string.format("num%d.bin", index // 10)
            watchface.chargeContChild1:set({ src = imgPath(src), x = 85 })
            watchface.chargeContChild1:clear_flag(lvgl.FLAG.HIDDEN)
            src = string.format("num%d.bin", index % 10)
            watchface.chargeContChild2:set({ src = imgPath(src), x = 97 })
            watchface.chargeContChild2:clear_flag(lvgl.FLAG.HIDDEN)
            watchface.chargeContChild3:set({ src = imgPath("num%.bin"), x = 113 })
            watchface.chargeContChild3:clear_flag(lvgl.FLAG.HIDDEN)
            s = 2
        else
            watchface.chargeImg:set({ x = 55 })
            src = string.format("num%d.bin", 1)
            watchface.chargeContChild1:set({ src = imgPath(src), x = 78 })
            watchface.chargeContChild1:clear_flag(lvgl.FLAG.HIDDEN)
            src = string.format("num%d.bin", 0)
            watchface.chargeContChild2:set({ src = imgPath(src), x = 91 })
            watchface.chargeContChild2:clear_flag(lvgl.FLAG.HIDDEN)
            src = string.format("num%d.bin", 0)
            watchface.chargeContChild3:set({ src = imgPath(src), x = 103 })
            watchface.chargeContChild3:clear_flag(lvgl.FLAG.HIDDEN)
            watchface.chargeContChild4:set({ src = imgPath("num%.bin"), x = 119 })
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

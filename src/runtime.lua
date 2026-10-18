-- A small timer drives state transitions; rendering happens only when state changes.
local function uiCreate()
    local root = lvgl.Object(nil, {
        w = lvgl.HOR_RES(), h = lvgl.VER_RES(), bg_color = 0,
        bg_opa = lvgl.OPA(100), border_width = 0, pad_all = 0,
    })
    root:clear_flag(lvgl.FLAG.SCROLLABLE)
    root:add_flag(lvgl.FLAG.CLICKABLE)
    root:add_flag(lvgl.FLAG.EVENT_BUBBLE)
    local watchface = createWatchface(root)
    local lastState, lastText, lastNight, lastBlink
    local active = true
    local eyeTime = math.random(7000, 10000)
    local function show(obj, visible)
        if visible then obj:clear_flag(lvgl.FLAG.HIDDEN)
        else obj:add_flag(lvgl.FLAG.HIDDEN) end
    end
    local function render()
        local now = lvgl.tick_get()
        local elapsed = (now - current_time) % 4294967296
        if MONIKA_STATE == 3 and elapsed >= 1000 then
            MONIKA_STATE = 2
            text = DEVICE.imageText and 21 or 41
            current_time = now
            elapsed = 0
        elseif MONIKA_STATE == 2 and elapsed >= 3000 then
            MONIKA_STATE = 1
            current_time = now
            elapsed = 0
            eyeTime = math.random(7000, 10000)
        elseif MONIKA_STATE == 1 and elapsed >= eyeTime + 400 then
            current_time = now
            elapsed = 0
            eyeTime = math.random(7000, 10000)
        end
        local night = getTime() == "night"
        local blink = MONIKA_STATE == 1 and elapsed >= eyeTime
        if lastState == MONIKA_STATE and lastText == text and lastNight == night and lastBlink == blink then return end
        local scare = MONIKA_STATE == 3
        local talking = MONIKA_STATE == 2
        watchface.objImage:set { src = imgPath(scare and "scare.bin" or (night and "bg_n.bin" or "bg.bin")) }
        show(watchface.time.widget, not scare)
        show(watchface.dateCont.widget, not scare)
        show(watchface.chargeCont.widget, not scare)
        show(watchface.msg.widget, talking)
        show(watchface.monikaEye.widget, not scare and (talking or blink))
        watchface.time.widget:set { y = talking and DEVICE.talkTimeY or DEVICE.timeY }
        watchface.dateCont.widget:set { y = talking and DEVICE.talkDateY or DEVICE.dateY }
        if talking or blink then
            local expression = talking and "smile" or "eye_close"
            watchface.monikaEye.widget:set { src = imgPath(expression .. (night and "_n" or "") .. ".bin") }
        end
        if talking then
            if DEVICE.imageText then
                watchface.text:set { src = imgPath("text/text" .. text .. ".bin") }
            else
                local message = string.format(totalText[text], heart)
                watchface.text:set { text = message }
                for i = 2, 9 do watchface["text" .. i]:set { text = message } end
            end
        end
        lastState, lastText, lastNight, lastBlink = MONIKA_STATE, text, night, blink
    end
    -- Reject invalid or out-of-range encoded sensor values before touching resources.
    local rawDataman = dataman
    local limits = {
        systemStatusBattery = 100, timeHourHigh = 2, timeHourLow = 9,
        timeMinuteHigh = 5, timeMinuteLow = 9, dateWeek = 6,
        dateMonth = 12, dateDay = 31, healthHeartRate = 249,
        healthStepCount = 1000000,
    }
    local dataman = {}
    function dataman.subscribe(key, obj, callback)
        return rawDataman.subscribe(key, obj, function(widget, encoded)
            if type(encoded) ~= "number" or encoded ~= encoded or encoded == 2147483647 or encoded < 0 then return end
            local value = encoded // 256
            if value > (limits[key] or 2147483646) then return end
            if (key == "dateMonth" or key == "dateDay" or key == "healthHeartRate") and value == 0 then return end
            callback(widget, encoded)
        end)
    end
    dataman.subscribe("systemStatusBattery", watchface.chargeCont.widget, function(obj, value)
        updateBattery(watchface, obj, value)
    end)
    -- BUILD_SUBSCRIPTIONS
    local function on()
        active = true
        text = return_text(getTime())
        MONIKA_STATE = 2
        current_time = lvgl.tick_get()
        lastState = nil
        render()
    end
    on()
    local timer = lvgl.Timer {
        period = 100, repeat_count = -1,
        cb = function() if active then render() end end,
    }
    timer:resume()
    function ScreenStateChangedCB(previous, current, reason)
        if current == "ON" and previous ~= "ON" then
            on()
            timer:resume()
        elseif current ~= "ON" then
            active = false
            timer:pause()
        end
    end
end
uiCreate()

-- Schedule the next animation deadline instead of polling every 100ms.
local function uiCreate()
    local root = lvgl.Object(nil, {
        w = lvgl.HOR_RES(), h = lvgl.VER_RES(), bg_color = 0,
        bg_opa = lvgl.OPA(100), border_width = 0, pad_all = 0,
    })
    root:clear_flag(lvgl.FLAG.SCROLLABLE)
    root:add_flag(lvgl.FLAG.CLICKABLE)
    root:add_flag(lvgl.FLAG.EVENT_BUBBLE)
    local watchface = createWatchface(root)
    local lastState, lastText, lastNight, lastBlink, lastHeart
    local active = true
    local eyeTime = math.random(7000, 10000)
    local night = getTime() == "night"
    local themeDeadline = animationTime + 60000
    local timer, scheduledDelay, scheduledAt
    local function syncExternalTime()
        if active and scheduledAt then
            -- os.time is available on devices, but only has second precision.
            local elapsed = math.max(0, math.min(scheduledDelay, (os.time() - scheduledAt) * 1000))
            animationTime = animationTime + elapsed
            scheduledDelay = scheduledDelay - elapsed
            scheduledAt = os.time()
        end
    end
    syncAnimationTime = syncExternalTime
    local function render()
        local heartValue = validHeart()
        local isHeartDialogue = dialogue.category == "heart"
        if isHeartDialogue and heartValue == nil then
            dialogue = pickDialogue("daily", dialogue)
        end
        local now = animationTime
        local elapsed = (now - current_time) % 4294967296
        if MONIKA_STATE == STATE.SCARE and elapsed >= 1000 then
            MONIKA_STATE = STATE.TALKING
            dialogue = dialogues.easterEgg[1]
            current_time = now
            elapsed = 0
        elseif MONIKA_STATE == STATE.TALKING and elapsed >= dialogueDuration(dialogue) then
            MONIKA_STATE = STATE.IDLE
            current_time = now
            elapsed = 0
            eyeTime = math.random(7000, 10000)
        elseif MONIKA_STATE == STATE.IDLE and elapsed >= eyeTime + 400 then
            current_time = now
            elapsed = 0
            eyeTime = math.random(7000, 10000)
        end
        if animationTime >= themeDeadline then
            night = getTime() == "night"
            themeDeadline = animationTime + 60000
        end
        local blink = MONIKA_STATE == STATE.IDLE and elapsed >= eyeTime
        if lastState == MONIKA_STATE and lastText == dialogue and lastNight == night and lastBlink == blink
            and (not isHeartDialogue or lastHeart == heartValue) then return end
        local scare = MONIKA_STATE == STATE.SCARE
        local talking = MONIKA_STATE == STATE.TALKING
        setChanged(watchface.objImage, { src = imgPath(scare and "scare.bin" or (night and "bg_n.bin" or "bg.bin")) })
        showChanged(watchface.time.widget, not scare)
        showChanged(watchface.dateCont.widget, not scare)
        showChanged(watchface.chargeCont.widget, not scare)
        showChanged(watchface.msg.widget, talking)
        showChanged(watchface.monikaEye.widget, not scare and (talking or blink))
        setChanged(watchface.time.widget, { y = talking and DEVICE.talkTimeY or DEVICE.timeY })
        setChanged(watchface.dateCont.widget, { y = talking and DEVICE.talkDateY or DEVICE.dateY })
        if talking or blink then
            local expression = talking and "smile" or "eye_close"
            setChanged(watchface.monikaEye.widget, { src = imgPath(expression .. (night and "_n" or "") .. ".bin") })
        end
        if talking then
            if DEVICE.imageText then
                setChanged(watchface.text, { src = imgPath(dialogue.image) })
            else
                local message = dialogueMessage(dialogue)
                setChanged(watchface.text, { text = message })
                for i = 2, 9 do setChanged(watchface["text" .. i], { text = message }) end
            end
        end
        lastState, lastText, lastNight, lastBlink = MONIKA_STATE, dialogue, night, blink
        lastHeart = heartValue
    end
    local function schedule()
        if not timer or not active then return end
        local elapsed = animationTime - current_time
        local duration
        if MONIKA_STATE == STATE.SCARE then duration = 1000
        elseif MONIKA_STATE == STATE.TALKING then duration = dialogueDuration(dialogue)
        else duration = elapsed < eyeTime and eyeTime or eyeTime + 400 end
        scheduledDelay = math.max(1, math.min(duration - elapsed, themeDeadline - animationTime))
        scheduledAt = os.time()
        timer:set { period = scheduledDelay }
        timer:resume()
    end
    refreshUI = function()
        if not active then return end
        render()
        schedule()
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
            if key == "healthHeartRate" then
                if type(encoded) ~= "number" or encoded ~= encoded or encoded == 2147483647
                    or encoded < 256 or encoded // 256 > limits.healthHeartRate then
                    heart, heartUpdatedAt = nil, nil
                    syncExternalTime()
                    refreshUI()
                    return
                end
            end
            if type(encoded) ~= "number" or encoded ~= encoded or encoded == 2147483647 or encoded < 0 then return end
            local value = encoded // 256
            if value > (limits[key] or 2147483646) then return end
            if (key == "dateMonth" or key == "dateDay" or key == "healthHeartRate") and value == 0 then return end
            callback(widget, encoded)
            if key == "healthHeartRate" then
                syncExternalTime()
                refreshUI()
            end
        end)
    end
    dataman.subscribe("systemStatusBattery", watchface.chargeCont.widget, function(obj, value)
        updateBattery(watchface, obj, value)
    end)
    subscribeData(dataman, watchface)
    local function on()
        active = true
        dialogue = return_text(getTime())
        MONIKA_STATE = STATE.TALKING
        current_time = animationTime
        lastState = nil
        night = getTime() == "night"
        themeDeadline = animationTime + 60000
        render()
        schedule()
    end
    timer = lvgl.Timer {
        period = 1000, repeat_count = -1,
        cb = function()
            if active then
                animationTime = animationTime + scheduledDelay
                render()
                schedule()
            end
        end,
    }
    on()
    function ScreenStateChangedCB(previous, current, reason)
        if current == "ON" and previous ~= "ON" then
            on()
        elseif current ~= "ON" then
            active = false
            timer:pause()
        end
    end
end
uiCreate()

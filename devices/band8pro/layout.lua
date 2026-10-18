local function createWatchface(parent)
    local t = {}

    local wfRoot = lvgl.Object(parent, {
        outline_width = 0,
        border_width = 0,
        pad_all = 0,
        bg_opa = 0,
        bg_color = 0,
        align = lvgl.ALIGN.CENTER,
        w = DEVICE.width,
        h = DEVICE.height,
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

    t.text = t.msg:setChild(imgPath("text/text1.bin"), { x = 13 + 18, y = 26 })

    wfRoot:onevent(lvgl.EVENT.SHORT_CLICKED, function(obj, code)
        local indev = lvgl.indev.get_act()
        local x, y = indev:get_point()
        if (y <= DEVICE.touchMaxY and MONIKA_STATE ~= 3) then
            MONIKA_STATE = 2
            text = return_text()
            current_time = animationTime
        end
    end)

    t.msg.widget:onevent(lvgl.EVENT.SHORT_CLICKED, function(obj, code)
        local indev = lvgl.indev.get_act()
        local x, y = indev:get_point()
        if (MONIKA_STATE ~= 1) then
            MONIKA_STATE = 1
            current_time = animationTime
        end
    end)

    return t
end


local function updateBattery(watchface, obj, value)
        local index = value // 256
        watchface.chargeContChild1:add_flag(lvgl.FLAG.HIDDEN)
        watchface.chargeContChild2:add_flag(lvgl.FLAG.HIDDEN)
        watchface.chargeContChild3:add_flag(lvgl.FLAG.HIDDEN)
        watchface.chargeContChild4:add_flag(lvgl.FLAG.HIDDEN)

        if index < 10 then
            local src = string.format("num%d.bin", index)
            watchface.chargeImg:set({ x = 138 })
            watchface.chargeContChild1:set({ src = imgPath(src), x = 162 })
            watchface.chargeContChild1:clear_flag(lvgl.FLAG.HIDDEN)
            watchface.chargeContChild2:set({ src = imgPath("num%.bin"), x = 178 })
            watchface.chargeContChild2:clear_flag(lvgl.FLAG.HIDDEN)
        elseif index < 100 then
            watchface.chargeImg:set({ x = 133 })
            local src = string.format("num%d.bin", index // 10)
            watchface.chargeContChild1:set({ src = imgPath(src), x = 159 })
            watchface.chargeContChild1:clear_flag(lvgl.FLAG.HIDDEN)
            local src = string.format("num%d.bin", index % 10)
            watchface.chargeContChild2:set({ src = imgPath(src), x = 171 })
            watchface.chargeContChild2:clear_flag(lvgl.FLAG.HIDDEN)
            watchface.chargeContChild3:set({ src = imgPath("num%.bin"), x = 187 })
            watchface.chargeContChild3:clear_flag(lvgl.FLAG.HIDDEN)

        else
            watchface.chargeImg:set({ x = 126 })
            local src = string.format("num%d.bin", 1)
            watchface.chargeContChild1:set({ src = imgPath(src), x = 149 })
            watchface.chargeContChild1:clear_flag(lvgl.FLAG.HIDDEN)
            local src = string.format("num%d.bin", 0)
            watchface.chargeContChild2:set({ src = imgPath(src), x = 163 })
            watchface.chargeContChild2:clear_flag(lvgl.FLAG.HIDDEN)
            local src = string.format("num%d.bin", 0)
            watchface.chargeContChild3:set({ src = imgPath(src), x = 174 })
            watchface.chargeContChild3:clear_flag(lvgl.FLAG.HIDDEN)
            watchface.chargeContChild4:set({ src = imgPath("num%.bin"), x = 190 })
            watchface.chargeContChild4:clear_flag(lvgl.FLAG.HIDDEN)

        end
    end

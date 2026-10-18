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
    t.chargeCont = imageGroup(wfRoot, { 0, 473 })
    t.chargeImg = t.chargeCont:setChild(imgPath("ap.bin"), { x = 151 }) -- 充电图标
    t.chargeContChild1 = t.chargeCont:setChild(imgPath("num1.bin"), { x = 181 });
    t.chargeContChild2 = t.chargeCont:setChild(imgPath("num0.bin"), { x = 203 });
    t.chargeContChild3 = t.chargeCont:setChild(imgPath("num0.bin"), { x = 224 });
    t.chargeContChild4 = t.chargeCont:setChild(imgPath("num%.bin"), { x = 246 });

    -- 小时分钟
    t.time = imageGroup(wfRoot, { 0, 300 })
    t.timeHourHigh = t.time:setChild(imgPath("0.bin"), { x = 35 })
    t.timeHourLow = t.time:setChild(imgPath("0.bin"), { x = 103 })
    t.timeGang = t.time:setChild(imgPath("num_mao.bin"), { x = 171 })
    t.timeMinuteHigh = t.time:setChild(imgPath("0.bin"), { x = 240 })
    t.timeMinuteLow = t.time:setChild(imgPath("0.bin"), { x = 308 })

    -- 日期
    t.dateCont = imageGroup(wfRoot, { 0, 396 })
    t.dateContChild1 = t.dateCont:setChild(imgPath("num0.bin"), { x = 101 });
    t.dateContChild2 = t.dateCont:setChild(imgPath("num8.bin"), { x = 120 });
    t.dateContChild3 = t.dateCont:setChild(imgPath("num_gang.bin"), { x = 139 });
    t.dateContChild4 = t.dateCont:setChild(imgPath("num1.bin"), { x = 158 });
    t.dateContChild5 = t.dateCont:setChild(imgPath("num6.bin"), { x = 177 });

    -- 星期
    t.dateWeek = t.dateCont:setChild(imgPath("mon.bin"), { x = 237 })

    t.monikaEye = Image(wfRoot, imgPath("eye_close.bin"), { 0, 100 })

    t.msg = imageGroup(wfRoot, { 0, 370 })
    t.msgBox = t.msg:setChild(imgPath("msg.bin"), { x = 26, y = 0 })

    t.text9 = t.msg:setText("", { w = 348, h = 68, x = 15 + 26, y = 23 }, "#000000")
    t.text8 = t.msg:setText("", { w = 348, h = 68, x = 15 + 26, y = 25 }, "#000000")
    t.text7 = t.msg:setText("", { w = 348, h = 68, x = 17 + 26, y = 23 }, "#000000")
    t.text6 = t.msg:setText("", { w = 348, h = 68, x = 17 + 26, y = 25 }, "#000000")
    t.text5 = t.msg:setText("", { w = 348, h = 68, x = 16 + 26, y = 25 }, "#000000")
    t.text4 = t.msg:setText("", { w = 348, h = 68, x = 16 + 26, y = 23 }, "#000000")
    t.text3 = t.msg:setText("", { w = 348, h = 68, x = 15 + 26, y = 24 }, "#000000")
    t.text2 = t.msg:setText("", { w = 348, h = 68, x = 17 + 26, y = 24 }, "#000000")
    t.text = t.msg:setText("", { w = 348, h = 68, x = 16 + 26, y = 24 }, "#ffffff")

    wfRoot:onevent(lvgl.EVENT.SHORT_CLICKED, function(obj, code)
        local indev = lvgl.indev.get_act()
        local x, y = indev:get_point()
        if (y <= DEVICE.touchMaxY and MONIKA_STATE ~= 3) then
            MONIKA_STATE = 2
            text = return_text()
            current_time = lvgl.tick_get()
        end
    end)

    t.msg.widget:onevent(lvgl.EVENT.SHORT_CLICKED, function(obj, code)
        local indev = lvgl.indev.get_act()
        local x, y = indev:get_point()
        if (MONIKA_STATE ~= 1) then
            MONIKA_STATE = 1
            current_time = lvgl.tick_get()
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
            watchface.chargeImg:set({ x = 172 })
            watchface.chargeContChild1:set({ src = imgPath(src), x = 202 })
            watchface.chargeContChild1:clear_flag(lvgl.FLAG.HIDDEN)
            watchface.chargeContChild2:set({ src = imgPath("num%.bin"), x = 224 })
            watchface.chargeContChild2:clear_flag(lvgl.FLAG.HIDDEN)
        elseif index < 100 then
            watchface.chargeImg:set({ x = 162 })
            local src = string.format("num%d.bin", index // 10)
            watchface.chargeContChild1:set({ src = imgPath(src), x = 192 })
            watchface.chargeContChild1:clear_flag(lvgl.FLAG.HIDDEN)
            local src = string.format("num%d.bin", index % 10)
            watchface.chargeContChild2:set({ src = imgPath(src), x = 213 })
            watchface.chargeContChild2:clear_flag(lvgl.FLAG.HIDDEN)
            watchface.chargeContChild3:set({ src = imgPath("num%.bin"), x = 235 })
            watchface.chargeContChild3:clear_flag(lvgl.FLAG.HIDDEN)

        else
            watchface.chargeImg:set({ x = 151 })
            local src = string.format("num%d.bin", 1)
            watchface.chargeContChild1:set({ src = imgPath(src), x = 181 })
            watchface.chargeContChild1:clear_flag(lvgl.FLAG.HIDDEN)
            local src = string.format("num%d.bin", 0)
            watchface.chargeContChild2:set({ src = imgPath(src), x = 203 })
            watchface.chargeContChild2:clear_flag(lvgl.FLAG.HIDDEN)
            local src = string.format("num%d.bin", 0)
            watchface.chargeContChild3:set({ src = imgPath(src), x = 224 })
            watchface.chargeContChild3:clear_flag(lvgl.FLAG.HIDDEN)
            watchface.chargeContChild4:set({ src = imgPath("num%.bin"), x = 246 })
            watchface.chargeContChild4:clear_flag(lvgl.FLAG.HIDDEN)

        end
    end

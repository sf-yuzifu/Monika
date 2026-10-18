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
    t.chargeCont = imageGroup(wfRoot, { 0, 492 })
    t.chargeImg = t.chargeCont:setChild(imgPath("ap.bin"), { x = 65 }) -- 充电图标
    t.chargeContChild1 = t.chargeCont:setChild(imgPath("num1.bin"), { x = 89 });
    t.chargeContChild2 = t.chargeCont:setChild(imgPath("num0.bin"), { x = 101 });
    t.chargeContChild3 = t.chargeCont:setChild(imgPath("num0.bin"), { x = 113 });
    t.chargeContChild4 = t.chargeCont:setChild(imgPath("num%.bin"), { x = 129 });

    -- 小时分钟
    t.time = imageGroup(wfRoot, { 0, 309 })
    t.timeHourHigh = t.time:setChild(imgPath("0.bin"), { x = 2 })
    t.timeHourLow = t.time:setChild(imgPath("0.bin"), { x = 42 })
    t.timeGang = t.time:setChild(imgPath("num_mao.bin"), { x = 78, y = -3 })
    t.timeMinuteHigh = t.time:setChild(imgPath("0.bin"), { x = 114 })
    t.timeMinuteLow = t.time:setChild(imgPath("0.bin"), { x = 154 })

    -- 日期
    t.dateCont = imageGroup(wfRoot, { 0, 377 })
    t.dateContChild1 = t.dateCont:setChild(imgPath("num0.bin"), { x = 46 });
    t.dateContChild2 = t.dateCont:setChild(imgPath("num8.bin"), { x = 58 });
    t.dateContChild3 = t.dateCont:setChild(imgPath("num_gang.bin"), { x = 68 });
    t.dateContChild4 = t.dateCont:setChild(imgPath("num1.bin"), { x = 78 });
    t.dateContChild5 = t.dateCont:setChild(imgPath("num6.bin"), { x = 89 });

    -- 星期
    t.dateWeek = t.dateCont:setChild(imgPath("mon.bin"), { x = 114, y = 2 })

    t.monikaEye = Image(wfRoot, imgPath("eye_close.bin"), { 0, 100 })

    t.msg = imageGroup(wfRoot, { 0, 381 })
    t.msgBox = t.msg:setChild(imgPath("msg.bin"), { x = 1, y = 0 })

    t.text9 = t.msg:setText("", { w = 190, h = 64, x = 9, y = 21 }, "#000000")
    t.text8 = t.msg:setText("", { w = 190, h = 64, x = 9, y = 23 }, "#000000")
    t.text7 = t.msg:setText("", { w = 190, h = 64, x = 11, y = 21 }, "#000000")
    t.text6 = t.msg:setText("", { w = 190, h = 64, x = 11, y = 23 }, "#000000")
    t.text5 = t.msg:setText("", { w = 190, h = 64, x = 10, y = 23 }, "#000000")
    t.text4 = t.msg:setText("", { w = 190, h = 64, x = 10, y = 21 }, "#000000")
    t.text3 = t.msg:setText("", { w = 190, h = 64, x = 9, y = 22 }, "#000000")
    t.text2 = t.msg:setText("", { w = 190, h = 64, x = 11, y = 22 }, "#000000")
    t.text = t.msg:setText("", { w = 190, h = 64, x = 10, y = 22 }, "#ffffff")

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
            watchface.chargeImg:set({ x = 76 })
            watchface.chargeContChild1:set({ src = imgPath(src), x = 102 })
            watchface.chargeContChild1:clear_flag(lvgl.FLAG.HIDDEN)
            watchface.chargeContChild2:set({ src = imgPath("num%.bin"), x = 118 })
            watchface.chargeContChild2:clear_flag(lvgl.FLAG.HIDDEN)
        elseif index < 100 then
            watchface.chargeImg:set({ x = 70 })
            local src = string.format("num%d.bin", index // 10)
            watchface.chargeContChild1:set({ src = imgPath(src), x = 96 })
            watchface.chargeContChild1:clear_flag(lvgl.FLAG.HIDDEN)
            local src = string.format("num%d.bin", index % 10)
            watchface.chargeContChild2:set({ src = imgPath(src), x = 108 })
            watchface.chargeContChild2:clear_flag(lvgl.FLAG.HIDDEN)
            watchface.chargeContChild3:set({ src = imgPath("num%.bin"), x = 124 })
            watchface.chargeContChild3:clear_flag(lvgl.FLAG.HIDDEN)

        else
            watchface.chargeImg:set({ x = 65 })
            local src = string.format("num%d.bin", 1)
            watchface.chargeContChild1:set({ src = imgPath(src), x = 89 })
            watchface.chargeContChild1:clear_flag(lvgl.FLAG.HIDDEN)
            local src = string.format("num%d.bin", 0)
            watchface.chargeContChild2:set({ src = imgPath(src), x = 101 })
            watchface.chargeContChild2:clear_flag(lvgl.FLAG.HIDDEN)
            local src = string.format("num%d.bin", 0)
            watchface.chargeContChild3:set({ src = imgPath(src), x = 113 })
            watchface.chargeContChild3:clear_flag(lvgl.FLAG.HIDDEN)
            watchface.chargeContChild4:set({ src = imgPath("num%.bin"), x = 129 })
            watchface.chargeContChild4:clear_flag(lvgl.FLAG.HIDDEN)

        end
    end

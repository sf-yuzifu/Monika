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

    -- 步数和心率
    dataman.subscribe("healthHeartRate", watchface.objImage, function(obj, value)
        heart = value // 256
    end)
    dataman.subscribe("healthStepCount", watchface.objImage, function(obj, value)
        step = value // 256
    end)


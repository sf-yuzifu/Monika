-- Data callbacks receive validated, 256-encoded values from the runtime wrapper.
local function subscribeData(dataman, watchface)
    local keys = { "timeHourHigh", "timeHourLow", false, "timeMinuteHigh", "timeMinuteLow" }
    for i, key in ipairs(keys) do
        if key then
            dataman.subscribe(key, watchface.time.widget:get_child(i - 1), function(obj, value)
                obj:set { src = imgPath(string.format("%d.bin", value // 256)) }
            end)
        end
    end
    dataman.subscribe("dateWeek", watchface.dateWeek, function(obj, value)
        local names = { "sun", "mon", "tue", "wed", "thu", "fri", "sat" }
        obj:set { src = imgPath(names[value // 256 + 1] .. ".bin") }
    end)
    local function dateDigits(first, second, value)
        local number = value // 256
        first:set { src = imgPath(string.format("num%d.bin", number // 10)) }
        second:set { src = imgPath(string.format("num%d.bin", number % 10)) }
    end
    dataman.subscribe("dateMonth", watchface.dateCont.widget, function(obj, value)
        dateDigits(watchface.dateContChild1, watchface.dateContChild2, value)
    end)
    dataman.subscribe("dateDay", watchface.dateCont.widget, function(obj, value)
        dateDigits(watchface.dateContChild4, watchface.dateContChild5, value)
    end)
    if not DEVICE.imageText then
        dataman.subscribe("healthHeartRate", watchface.objImage, function(obj, value)
            heart = value // 256
            heartUpdatedAt = os.time()
        end)
        dataman.subscribe("healthStepCount", watchface.objImage, function(obj, value)
            step = value // 256
        end)
    end
end

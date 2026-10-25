-- Daylight-only face: data subscriptions, no animation timer or touch handlers.
local root = lvgl.Object(nil, {
    w = lvgl.HOR_RES(), h = lvgl.VER_RES(), bg_color = 0,
    bg_opa = lvgl.OPA(100), border_width = 0, pad_all = 0,
})
root:clear_flag(lvgl.FLAG.SCROLLABLE)
root:add_flag(lvgl.FLAG.CLICKABLE)
root:add_flag(lvgl.FLAG.EVENT_BUBBLE)
local watchface = createWatchface(root)
local limits = {
    systemStatusBattery = 100, timeHourHigh = 2, timeHourLow = 9,
    timeMinuteHigh = 5, timeMinuteLow = 9, dateWeek = 6, dateMonth = 12, dateDay = 31,
}
local validated = {}
function validated.subscribe(key, obj, callback)
    return dataman.subscribe(key, obj, function(widget, encoded)
        if type(encoded) ~= "number" or encoded ~= encoded or encoded == 2147483647 or encoded < 0 then return end
        local value = encoded // 256
        if value > limits[key] then return end
        if (key == "dateMonth" or key == "dateDay") and value == 0 then return end
        callback(widget, encoded)
    end)
end
validated.subscribe("systemStatusBattery", watchface.chargeCont.widget, function(obj, value)
    updateBattery(watchface, obj, value)
end)
subscribeData(validated, watchface)

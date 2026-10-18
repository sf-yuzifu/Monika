-- Device-specific coordinates live in DEVICE.layout; behavior is shared.
local function setChanged(obj, values)
    local cached = propertyCache[obj]
    if not cached then cached = {}; propertyCache[obj] = cached end
    local changed = {}
    local dirty = false
    for key, value in pairs(values) do
        if cached[key] ~= value then
            changed[key] = value
            cached[key] = value
            dirty = true
        end
    end
    if dirty then obj:set(changed) end
end

local visibilityCache = {}
local function showChanged(obj, visible)
    if visibilityCache[obj] == visible then return end
    visibilityCache[obj] = visible
    if visible then obj:clear_flag(lvgl.FLAG.HIDDEN)
    else obj:add_flag(lvgl.FLAG.HIDDEN) end
end

local function createWatchface(parent)
    local t = {}
    local layout = DEVICE.layout
    local face = lvgl.Object(parent, {
        outline_width = 0, border_width = 0, pad_all = 0,
        bg_opa = 0, bg_color = 0, align = lvgl.ALIGN.CENTER,
        w = DEVICE.width, h = DEVICE.height,
    })
    face:clear_flag(lvgl.FLAG.SCROLLABLE)
    face:add_flag(lvgl.FLAG.EVENT_BUBBLE)
    t.objImage = lvgl.Image(face, { x = 0, y = 0, src = imgPath("bg.bin") })
    propertyCache[t.objImage] = { src = imgPath("bg.bin") }
    for _, group in ipairs(layout.groups) do
        if group.name == "msg" then
            t.monikaEye = Image(face, imgPath("eye_close.bin"), { layout.eyeX, layout.eyeY })
            propertyCache[t.monikaEye.widget] = { src = imgPath("eye_close.bin") }
        end
        local y = group.y
        if group.name == "time" then y = DEVICE.timeY
        elseif group.name == "dateCont" then y = DEVICE.dateY end
        local container = imageGroup(face, { group.x, y })
        t[group.name] = container
        propertyCache[container.widget] = { y = y }
        for _, child in ipairs(group.children) do
            t[child.name] = container:setChild(imgPath(child.image), { x = child.x, y = child.y })
        end
    end
    if not DEVICE.imageText then
        local label = layout.text
        local offsets = { {-1,-1}, {-1,1}, {1,-1}, {1,1}, {0,1}, {0,-1}, {-1,0}, {1,0}, {0,0} }
        for i, offset in ipairs(offsets) do
            local name = i == 9 and "text" or "text" .. (10 - i)
            t[name] = t.msg:setText("", {
                w = label.w, h = label.h,
                x = label.x + offset[1], y = label.y + offset[2],
            }, i == 9 and "#ffffff" or "#000000")
        end
    end
    face:onevent(lvgl.EVENT.SHORT_CLICKED, function()
        local indev = lvgl.indev.get_act()
        local x, y = indev:get_point()
        if y <= DEVICE.touchMaxY and MONIKA_STATE ~= 3 then
            syncAnimationTime()
            MONIKA_STATE = 2
            text = return_text()
            current_time = animationTime
            refreshUI()
        end
    end)
    t.msg.widget:onevent(lvgl.EVENT.SHORT_CLICKED, function()
        if MONIKA_STATE ~= 1 then
            syncAnimationTime()
            MONIKA_STATE = 1
            current_time = animationTime
            refreshUI()
        end
    end)
    return t
end

local function updateBattery(watchface, obj, encoded)
    local value = encoded // 256
    local digits = tostring(value)
    local positions = DEVICE.layout.battery[#digits]
    setChanged(watchface.chargeImg, { x = positions[1] })
    for i = 1, 4 do
        local child = watchface["chargeContChild" .. i]
        local visible = i <= #digits + 1
        if visible then
            local filename = i <= #digits and "num" .. digits:sub(i, i) .. ".bin" or "num%.bin"
            setChanged(child, { x = positions[i + 1], src = imgPath(filename) })
        end
        showChanged(child, visible)
    end
end

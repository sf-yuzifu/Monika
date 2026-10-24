local function Image(root, src, pos)
    return { widget = root:Image { src = src, x = pos[1], y = pos[2] } }
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
        x = pos[1],
        y = pos[2],
    })

    function t:setChild(src, pos)
        local img = t.widget:Image { src = src, x = pos.x, y = pos.y }
        return img
    end

    function t:setText(text, pos, color)
        local stext = t.widget:Label { w = pos.w,
            h = pos.h,
            x = pos.x,
            y = pos.y,
            text = text,
            text_color = color,
            font_size = DEVICE.fontSize,
            text_font = textFont(),
        }
        return stext
    end

    return t
end



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
        local children = group.children
        local order = {}
        if group.name == "chargeCont" then
            -- LVGL draws later children on top: highest digit must be last.
            for i = #children, 1, -1 do order[#order + 1] = children[i] end
        else
            order = children
        end
        for _, child in ipairs(order) do
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
    else
        t.text = t.msg:setChild(imgPath(dialogues.morning[1].image), layout.imageTextPosition)
    end
    face:onevent(lvgl.EVENT.SHORT_CLICKED, function()
        local indev = lvgl.indev.get_act()
        local x, y = indev:get_point()
        if y <= DEVICE.touchMaxY and MONIKA_STATE ~= STATE.SCARE then
            syncAnimationTime()
            MONIKA_STATE = STATE.TALKING
            dialogue = return_text()
            current_time = animationTime
            refreshUI()
        elseif y >= DEVICE.touchBatteryMinY and MONIKA_STATE ~= STATE.SCARE and
            (not DEVICE.touchBatteryBounds or
             (x >= DEVICE.touchBatteryBounds[1] and y >= DEVICE.touchBatteryBounds[2] and
              x <= DEVICE.touchBatteryBounds[3] and y <= DEVICE.touchBatteryBounds[4])) then
            syncAnimationTime()
            MONIKA_STATE = STATE.TALKING
            dialogue = toggleScareDialogue()
            current_time = animationTime
            refreshUI()
        end
    end)
    t.msg.widget:onevent(lvgl.EVENT.SHORT_CLICKED, function()
        if MONIKA_STATE ~= STATE.IDLE then
            syncAnimationTime()
            MONIKA_STATE = STATE.IDLE
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

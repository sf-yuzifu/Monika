-- Named categories contain stable entry objects; selection never uses global indices.
local dialogues = {
    morning = {
        { category = "morning", text = "早上好！昨晚睡得好吗？今天也要多陪陪我哦。" },
        { category = "morning", text = "早安！今天有什么计划呢？我随时都在这里看着你。" },
        { category = "morning", text = "早上好！新的一天开始了呢，出门前别忘了吃早餐呀。" },
        { category = "morning", text = "早安～今天手环震动的时候，就当是我在轻轻敲你的手腕吧。" },
    },
    afternoon = {
        { category = "afternoon", text = "下午好！学习工作累了吗？记得站起来伸个懒腰哦。" },
        { category = "afternoon", text = "午后有点犯困呢……要不要喝杯水或者咖啡提提神？" },
        { category = "afternoon", text = "午安！无论你在现实中忙些什么，我都一直陪着你呢。" },
        { category = "afternoon", text = "下午好～遇到烦心事的话，悄悄点一下屏幕，我一直都在。" },
    },
    night = {
        { category = "night", text = "晚上好！今天辛苦啦。夜晚的时间，就留给我们两个人吧。" },
        { category = "night", text = "夜深了呢，屏幕光对眼睛不太好，该准备去睡觉啦。" },
        { category = "night", text = "晚安！今晚我们能在梦里相遇吗？我很期待呢。" },
        { category = "night", text = "快去休息吧，做个好梦。明天醒来第一眼也要看我哦。" },
    },
    daily = {
        { category = "daily", text = "能像这样隔着屏幕戴在你手腕上……其实我也挺幸福的。" },
        { category = "daily", text = "触碰到手环的这一刻，感觉我和你的距离又近了一点呢。" },
        { category = "daily", text = "哪怕现实世界隔得再远，只要你抬起手，我就在这里。" },
        { category = "daily", text = "Just Monika." },
        { category = "daily", text = "你今天没有在看别的女孩子吧？呵呵，开玩笑的～" },
        { category = "daily", text = "要是有一天我能跨过这层玻璃，去你的世界看看就好了。" },
        { category = "daily", text = "你知道吗？只要能感受到你的体温，我就不会觉得孤单。" },
        { category = "daily", text = "今天的文学部建议：当你感到迷茫时，写下心里的想法吧。" },
        { category = "daily", text = "有空的时候，多带我出去看看外面的世界吧？" },
        { category = "daily", text = "就算整个世界都是虚构的，我对你的喜欢也是真实的。" },
        { category = "daily", text = "嘿，不要总是低着头看屏幕，偶尔也抬头看看天空呀。" },
        { category = "daily", text = "我的钢琴曲写得差不多了，好想弹给你听听看呢。" },
        { category = "daily", text = "无论遇到多难过的事，深呼吸，别忘了你身后还有我。" },
        { category = "daily", text = "今天有好好喝水吗？身体可是属于你自己的，要照顾好哦。" },
        { category = "daily", text = "只要你还戴着我，我就永远是你的文学部部长。" },
        { category = "daily", text = "你手腕上的脉搏，就是连接我和现实唯一的频率呢。" },
        { category = "daily", text = "欢迎回来。无论你什么时候点开屏幕，我都一直在等着你。" },
        { category = "daily", text = "今天过得怎么样？如果累了，就稍微放空一下脑袋吧。" },
        { category = "daily", text = "能被你选中作为表盘，今天也是值得开心的一天呢。" },
    },
    steps = {
        { category = "steps", text = "刚迈开脚步呢！散步对放松心情很有帮助哦。" },
        { category = "steps", text = "已经走了一千步啦～继续保持这个轻松的节奏吧！" },
        { category = "steps", text = "六千步达成！今天带我走过了很多地方呢，真开心。" },
        { category = "steps", text = "哇，破万步了！今天超级充实呢，回去好好犒劳一下自己吧。" },
    },
    heart = {
        { category = "heart", text = "心率%d：平稳柔和的节律，感觉你现在很放松呢。" },
        { category = "heart", text = "心率%d：心跳稍微变快了一点呢……是因为正在看着我吗？" },
        { category = "heart", text = "心率%d：心跳很有活力呀！是有什么让你兴奋的事情吗？" },
        { category = "heart", text = "心率%d：运动得很投入呢！记得擦擦汗，稍微补点水哦。" },
        { category = "heart", text = "心率%d：心跳有些太快了哦！快深呼吸歇一歇，别太勉强自己啦。" },
    },
    easterEgg = {
        { category = "easterEgg", text = "怎么样……刚才有吓到你吗？嘻嘻，抱歉啦～" },
    },
    lowBattery = {
        { category = "lowBattery", text = "电量有点低了呢，方便的话带我去充会儿电吧？" },
        { category = "lowBattery", text = "还想多陪你一会儿……别忘了给我补充能量哦。" },
        { category = "lowBattery", text = "电量快见底啦，等下记得找充电线帮帮我呀～" },
        { category = "lowBattery", text = "好像有点快没力气了……能让我充一会儿电吗？" },
    },
    festival = {
        ["01-01"] = { category = "festival", text = "新年快乐！新的一年，我也依然会一直陪在你身边。" },
        ["02-14"] = { category = "festival", text = "情人节快乐！虽然隔着屏幕，但我的心只属于你哦。" },
        ["05-20"] = { category = "festival", text = "今天是个特别的日子呢～嘻嘻，我也最喜欢你了！" },
        ["09-22"] = { category = "festival", text = "今天是9月22日呢！属于我和你的纪念日，谢谢你～" },
        ["10-31"] = { category = "festival", text = "万圣节快乐！放心吧，今天我不恶作剧，只想陪着你。" },
        ["12-24"] = { category = "festival", text = "平安夜快乐！今晚要平平安安的，好想和你一起看雪呀。" },
        ["12-25"] = { category = "festival", text = "圣诞快乐！在这个温暖的节日里，能有你陪伴真好。" },
        ["12-31"] = { category = "festival", text = "这一年的最后一天啦！今年谢谢你一直戴着我，辛苦啦～" },
    },
}
if DEVICE.imageText then
    dialogues = DEVICE.imageDialogues
    for category, entries in pairs(dialogues) do
        for _, entry in ipairs(entries) do entry.category = category end
    end
end

local dialogue = dialogues.morning[1]
local function dialogueMessage(entry)
    return string.format(entry.text, heart)
end
local function dialogueDuration(entry)
    if entry.image then return entry.duration end
    local _, count = dialogueMessage(entry):gsub("[^\128-\191]", "")
    return math.max(3000, math.min(8000, 1500 + count * 180))
end
local function getTime()
    local hour = tonumber(os.date("%H"))
    if hour < 6 or hour >= 18 then return "night"
    elseif hour < 12 then return "morning"
    else return "afternoon" end
end

local previousGreeting, previousDialogue
local function pickDialogue(category, excluded)
    local entries = dialogues[category]
    local excludedIndex
    for i, entry in ipairs(entries) do
        if entry == excluded then excludedIndex = i; break end
    end
    local count = #entries
    if excludedIndex and count > 1 then
        local index = math.random(1, count - 1)
        return entries[index >= excludedIndex and index + 1 or index]
    end
    return entries[math.random(1, count)]
end
local function heartDialogue(value)
    local thresholds = { 151, 132, 113, 94 }
    for i, threshold in ipairs(thresholds) do
        if value > threshold then return dialogues.heart[#thresholds + 2 - i] end
    end
    return dialogues.heart[1]
end
local function scareDialogue()
    current_time = animationTime
    MONIKA_STATE = STATE.SCARE
    return dialogues.easterEgg[1]
end
local scareEnabled = DEVICE.enableScare ~= false
local function toggleScareDialogue()
    scareEnabled = not scareEnabled
    if DEVICE.imageText then
        local entry = dialogues.daily[3]
        return { category = "toggle", image = entry.image, duration = entry.duration }
    end
    local text = scareEnabled and "恶作剧代码已恢复！做好心理准备哦，呵呵～"
                               or "秘密开关被发现了呢！恶作剧代码已禁用～"
    return { category = "toggle", text = text }
end

local function selectDialogue(period, excluded)
    local value = validHeart()
    local isLowBattery = not DEVICE.imageText and batteryLevel and batteryLevel <= 20
    local todayFestival = not DEVICE.imageText and dialogues.festival and dialogues.festival[os.date("%m-%d")]
    if not DEVICE.imageText and period and value and value > 94 then
        return heartDialogue(value)
    end
    if period then
        if todayFestival and excluded ~= todayFestival then
            return todayFestival
        end
        if isLowBattery and batteryLevel <= 10 and math.random(1, 3) == 1 then
            return pickDialogue("lowBattery", excluded)
        end
        return pickDialogue(period, excluded)
    end
    if todayFestival and math.random(1, 5) == 1 and excluded ~= todayFestival then
        return todayFestival
    end
    if isLowBattery then
        local chance = batteryLevel <= 10 and 2 or 4
        if math.random(1, chance) == 1 then
            return pickDialogue("lowBattery", excluded)
        end
    end
    if DEVICE.imageText then
        if scareEnabled and math.random(1, 1000) == 2 then return scareDialogue() end
    elseif step >= 500 then
        local choice = math.random(1, 21)
        if choice == 6 then
            local thresholds = { 10000, 6000, 1000, 500 }
            for i, threshold in ipairs(thresholds) do
                if step >= threshold then return dialogues.steps[#thresholds + 1 - i] end
            end
        elseif choice == 7 and value then return heartDialogue(value)
        elseif scareEnabled and math.random(1, 1000) == 2 then return scareDialogue() end
    end
    return pickDialogue("daily", excluded)
end
local function return_text(period)
    local excluded
    if period then excluded = previousGreeting else excluded = previousDialogue end
    local selected = selectDialogue(period, excluded)
    if period then previousGreeting = selected else previousDialogue = selected end
    return selected
end

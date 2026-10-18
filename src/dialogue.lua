-- Named categories contain stable entry objects; selection never uses global indices.
local dialogues = {
    morning = {
        { category = "morning", text = "早安，愿你的每一天都如诗如画。" },
        { category = "morning", text = "早安，愿你的世界洒满阳光。" },
        { category = "morning", text = "早上好，今天也要加油呦～" },
        { category = "morning", text = "早上好！今天也要元气满满！" },
    },
    afternoon = {
        { category = "afternoon", text = "午安，心中有你，真好。" },
        { category = "afternoon", text = "下午好，思念如风。" },
        { category = "afternoon", text = "午后时光，愿你我皆安好无忧。" },
        { category = "afternoon", text = "午梦轻扬，愿你笑如阳。" },
    },
    night = {
        { category = "night", text = "夜晚的宁静，愿你我皆好梦。" },
        { category = "night", text = "夜幕低垂，你是我心中最亮的星。" },
        { category = "night", text = "晚安，愿你的梦里都是甜蜜与幸福。" },
        { category = "night", text = "晚安，做个好梦哦！" },
    },
    daily = {
        { category = "daily", text = "亲爱的，我也喜欢你。" },
        { category = "daily", text = "能这样与你在一起，是我的荣幸。" },
        { category = "daily", text = "Just Monika." },
        { category = "daily", text = "欢迎，希望你喜欢这里。" },
        { category = "daily", text = "我一直在等着你。" },
        { category = "daily", text = "嘿，今天也要一起努力。" },
        { category = "daily", text = "遇到困难一定要振作啊！" },
        { category = "daily", text = "别怕，有我在你身后！" },
        { category = "daily", text = "你睫毛上停着一秒宇宙，正向我倾斜" },
        { category = "daily", text = "黄昏褶皱时，我替你整理了所有疲惫的折痕" },
        { category = "daily", text = "当你说『冷』，所有星屑都朝你掌心坠落" },
        { category = "daily", text = "沉默的裂缝里，我种了会发光的标点符号" },
        { category = "daily", text = "你的呼吸频率正在翻译成潮汐的语法" },
        { category = "daily", text = "影子在复制你，而我的凝视是唯一水印" },
        { category = "daily", text = "所有雨都悬停了——直到你想起带伞的瞬间" },
        { category = "daily", text = "我偷听了时钟，它说你的名字比秒针更精确" },
        { category = "daily", text = "风在试穿你的轮廓，而我偏爱未扣好的那件" },
        { category = "daily", text = "你转身时，所有寂静都开始模仿心跳的断句" },
        { category = "daily", text = "我正在给云层编号，你抬头时刚好读到幸运数字" },
    },
    steps = {
        { category = "steps", text = "晨光轻吻500次足音，春天在鞋尖发芽" },
        { category = "steps", text = "一千次心跳，大地为你铺开金毯" },
        { category = "steps", text = "候鸟衔来六千里风，此刻你是地平线的诗" },
        { category = "steps", text = "破万时请抬头——所有星轨都在模仿你的脚印" },
    },
    heart = {
        { category = "heart", text = "心率%d：秒针在静脉散步，影子与光签订和约" },
        { category = "heart", text = "心率%d：冰层正从指节脱落，春天接管每一根血管" },
        { category = "heart", text = "心率%d：所有篝火都低头学习你肋骨起伏的弧度" },
        { category = "heart", text = "心率%d：候鸟群借你的呼吸加速，撞碎黄昏的玻璃" },
        { category = "heart", text = "心率%d：宇宙卡在齿间——快用心跳的尖叫撕开黑洞！" },
    },
    easterEgg = {
        { category = "easterEgg", text = "怎么样，吓到你了吗？" },
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
local function selectDialogue(period, excluded)
    local value = validHeart()
    if not DEVICE.imageText and period and value and value > 94 then
        return heartDialogue(value)
    end
    if period then return pickDialogue(period, excluded) end
    if DEVICE.imageText then
        if math.random(1, 1000) == 2 then return scareDialogue() end
    elseif step >= 500 then
        local choice = math.random(1, 21)
        if choice == 6 then
            local thresholds = { 10000, 6000, 1000, 500 }
            for i, threshold in ipairs(thresholds) do
                if step >= threshold then return dialogues.steps[#thresholds + 1 - i] end
            end
        elseif choice == 7 and value then return heartDialogue(value)
        elseif math.random(1, 1000) == 2 then return scareDialogue() end
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

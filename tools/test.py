"""Execute generated Lua with a mock LVGL runtime to verify interaction/lifecycle."""
from lupa.lua54 import LuaRuntime
import xml.etree.ElementTree as ET
import struct
from PIL import Image
from build import resources, source_for
from config import ROOT, load_devices

MOCK = r'''
now = 0
clockOffset = 0
os.time = function() return 1800000000 + now // 1000 + clockOffset end
pointX, pointY = 100, 100
SCRIPT_PATH = "assets/"
subscriptions = {}
timers = {}
clicks = {}
local methods = {}
writes = {}
function methods:set(values)
    if values.src then validateImage(values.src) end
    writes[#writes+1]={obj=self,kind="set",values=values}
    for k,v in pairs(values) do self[k] = v end
end
function methods:add_flag(flag)
    writes[#writes+1]={obj=self,kind="flag"}; self.flags[flag] = true
end
function methods:clear_flag(flag)
    writes[#writes+1]={obj=self,kind="flag"}; self.flags[flag] = nil
end
function methods:get_child(i) return self.children[i+1] end
function methods:onevent(event, callback) clicks[#clicks+1] = {obj=self, cb=callback} end
local function object(parent, values)
    local result = setmetatable({flags={},children={},parent=parent}, {__index=methods})
    result:set(values or {})
    if parent then parent.children[#parent.children+1] = result end
    return result
end
local function image(parent, values)
    local result = object(parent, values)
    result.w,result.h = imageSize(values.src)
    return result
end
function methods:Image(values) return image(self, values) end
function methods:Label(values) return object(self, values) end
lvgl = {
    Object=object, Image=image, SIZE_CONTENT=-1,
    ALIGN={CENTER=0}, FLAG={SCROLLABLE=1,EVENT_BUBBLE=2,HIDDEN=3,CLICKABLE=4},
    EVENT={SHORT_CLICKED=1}, BUILTIN_FONT={MONTSERRAT_14=14},
    HOR_RES=function() return screenWidth end, VER_RES=function() return screenHeight end,
    OPA=function(n) return n end,
    Font=function(name,size)
        fontAttempts[#fontAttempts+1]=name
        if rejectedFonts[name] or rejectAllFonts then error("font unavailable: " .. name) end
        return size
    end,
    indev={get_act=function() return {get_point=function() return pointX,pointY end} end},
}
function lvgl.Timer(values)
    function values:set(opts)
        assert(type(opts.period) == "number" and opts.period > 0, "positive timer period required")
        for k,v in pairs(opts) do self[k]=v end
        self.due=now+self.period
    end
    function values:resume() self.paused=false; self.due=now+self.period end
    function values:pause() self.paused=true end
    timers[#timers+1]=values
    return values
end
package.preload.lvgl=function() return lvgl end
package.preload.dataman=function() return {subscribe=function(key,obj,cb)
    subscriptions[key]={obj=obj,cb=cb}; return key
end} end
function emit(key,value)
    local sub=subscriptions[key]
    if sub then sub.cb(sub.obj,value) end
end
function advance(ms)
    local target=now+ms
    while true do
        local nextTimer
        for _,timer in ipairs(timers) do
            if not timer.paused and timer.due <= target and (not nextTimer or timer.due < nextTimer.due) then nextTimer=timer end
        end
        if not nextTimer then break end
        now=nextTimer.due
        nextTimer.due=now+nextTimer.period
        timerCallbacks=(timerCallbacks or 0)+1
        nextTimer.cb()
    end
    now=target
end
function click(i) clicks[i].cb(clicks[i].obj,1) end
function tap(obj,x,y)
    pointX,pointY=x,y
    while obj do
        for _,event in ipairs(clicks) do
            if event.obj == obj then event.cb(obj,1) end
        end
        if not obj.flags[lvgl.FLAG.EVENT_BUBBLE] then break end
        obj=obj.parent
    end
    pointX,pointY=100,100
end
function delayedCallback(delay)
    local timer=timers[1]
    check(not timer.paused, "timer must be active")
    now=math.max(now,timer.due)+delay
    timer.due=now+timer.period
    timer.cb()
end
function check(condition,message) assert(condition,message) end
fontAttempts = {}
rejectedFonts = {}
'''


def image_size(path):
    data = path.read_bytes()
    if data[:8] == b"\x89PNG\r\n\x1a\n":
        with Image.open(path) as image:
            image.load()  # Check actual PNG decoding, not only the header.
            return image.size
    header = struct.unpack("<I", data[:4])[0]
    width, height = (header >> 10) & 2047, (header >> 21) & 2047
    assert width > 0 and height > 0, (path, "invalid LVGL image dimensions")
    return width, height


def main():
    devices = load_devices()
    for name, config in devices.items():
        target = config.get("packageAlias", name)
        project_path = ROOT / "build" / target / "monika.fprj"
        if project_path.exists():
            project = ET.parse(project_path)
            widget = project.find("Screen/Widget")
            assert int(project.getroot().get("DeviceType")) == config["deviceType"]
            assert (int(widget.get("Width")), int(widget.get("Height"))) == (config["width"], config["height"])
        source = source_for(config)
        selected = resources(config)
        packaged_names = {
            (resource.removesuffix(".bin") + ".png") if path.suffix == ".png" else resource
            for resource, path in selected.items()
        }
        dimensions = {
            resource.removesuffix(".bin") + ".png" if path.suffix == ".png" else resource: image_size(path)
            for resource, path in selected.items()
        }
        assert dimensions["bg.png"] == (config["width"], config["height"])
        assert dimensions["bg_n.png"] == dimensions["bg.png"]
        for image in ["smile.png", "smile_n.png", "eye_close.png", "eye_close_n.png"]:
            assert dimensions[image] == dimensions["eye_close.png"], (name, image)
        if project_path.exists():
            app = project_path.parent / "app/_lua/monika"
            generated_source = (app / "monika.lua").read_text(encoding="utf-8")
            assert generated_source == source_for(devices[target]), f"{name}: stale project; run tools/build.py"
            for resource, path in selected.items():
                filename = resource.removesuffix(".bin") + ".png" if path.suffix == ".png" else resource
                assert (app / filename).read_bytes() == path.read_bytes(), (name, filename)
        for resource, path in selected.items():
            if path.suffix != ".png":
                continue
            data = path.read_bytes()
            assert data[:8] == b"\x89PNG\r\n\x1a\n"
            size = struct.unpack(">II", data[16:24])
            legacy = ROOT / "devices" / config["assets"] / resource
            if legacy.exists():
                old = legacy.read_bytes()
                if old[:8] == b"\x89PNG\r\n\x1a\n":
                    old_size = struct.unpack(">II", old[16:24])
                else:
                    header = struct.unpack("<I", old[:4])[0]
                    old_size = ((header >> 10) & 2047, (header >> 21) & 2047)
                assert size == old_size, (name, resource, size, old_size)
            generated = project_path.parent / "app/_lua/monika" / path.name
            if project_path.exists():
                assert generated.read_bytes() == data, (name, resource)
        runtime = LuaRuntime(unpack_returned_tuples=True)
        used_images = set()
        def validate_image(path):
            assert path.startswith("assets/"), (name, path)
            filename = path.removeprefix("assets/")
            assert filename in packaged_names, (name, "unpacked image", filename)
            used_images.add(filename)
        runtime.globals().validateImage = validate_image
        runtime.globals().imageSize = lambda path: dimensions[path.removeprefix("assets/")]
        runtime.globals().screenWidth = config["width"]
        runtime.globals().screenHeight = config["height"]
        runtime.execute(MOCK)
        runtime.execute(source + "\n_testDuration = dialogueDuration\n_testCatalog = dialogues\n_testSelect = return_text\n_testCurrent = function() return dialogue end\n_testState = function() return MONIKA_STATE end\n_testRefresh = refreshUI\n_testValidHeart = validHeart\n_testScareEnabled = function() return scareEnabled end")
        runtime.execute('''
            check(lvgl.tick_get == nil, "tick_get must remain unavailable")
            check(clicks[1].obj.Anim == nil and clicks[1].obj.get_img_size == nil,
                  "unused placeholder interfaces must remain absent")
            local background=clicks[1].obj.children[1]
            check(background.w == screenWidth and background.h == screenHeight, "real background dimensions")
        ''')
        if not config["imageText"]:
            for failure_mode in ["first", "all"]:
                probe = LuaRuntime(unpack_returned_tuples=True)
                probe.globals().validateImage = validate_image
                probe.globals().imageSize = lambda path: dimensions[path.removeprefix("assets/")]
                probe.globals().screenWidth = config["width"]
                probe.globals().screenHeight = config["height"]
                probe.execute(MOCK)
                if failure_mode == "first":
                    probe.globals().rejectedFonts[config["fonts"][0]] = True
                else:
                    probe.globals().rejectAllFonts = True
                probe.execute(source + "\n_testFont = textFont")
                attempts = len(probe.globals().fontAttempts)
                assert attempts == (2 if failure_mode == "first" else len(config["fonts"])), (name, failure_mode)
                expected = config["fontSize"] if failure_mode == "first" else 14
                assert probe.globals()._testFont() == expected
                assert len(probe.globals().fontAttempts) == attempts, "font cache must prevent retries"
        if not config["imageText"]:
            runtime.execute('''
                local random = math.random
                math.random = function(a,b) if b == 21 then return 6 else return a end end
                local cases = {
                    {499, false}, {500,32}, {501,32},
                    {999,32}, {1000,33}, {1001,33},
                    {5999,33}, {6000,34}, {6001,34},
                    {9999,34}, {10000,35}, {10001,35},
                }
                for _,case in ipairs(cases) do
                    emit("healthStepCount",case[1]*256)
                    local selected = _testSelect()
                    if case[2] then check(selected == _testCatalog.steps[case[2]-31], "inclusive step threshold " .. case[1])
                    else check(selected.category == "daily", "below 500 uses daily dialogue") end
                end
                emit("healthStepCount",0)
                math.random = random
            ''')
        runtime.execute('''
            local random = math.random
            math.random = function(a,b) return a end
            advance(8100)
            local face = clicks[1].obj
            local eye = face.children[5]
            writes = {}
            advance(7500)
            check(#writes > 0, "blink changes eye")
            for _,write in ipairs(writes) do
                check(write.obj == eye, "blink only updates eye, not background/layout/text")
            end
            click(1); advance(100)
            writes = {}
            click(1); advance(100)
            check(#writes > 0, "new dialogue updates content")
            for _,write in ipairs(writes) do
                check(write.kind == "set" and (write.values.text ~= nil or write.values.src ~= nil), "dialogue only updates content")
                check(write.obj ~= face.children[1] and write.obj ~= eye, "dialogue preserves background and eye")
            end
            writes = {}; advance(100)
            check(#writes == 0, "unchanged state performs no UI writes")
            math.random = random
        ''')
        duration = runtime.globals()._testDuration
        catalog = runtime.globals()._testCatalog
        if config["imageText"]:
            assert sum(map(len, config["imageDialogues"].values())) == 21
            for category, entries in config["imageDialogues"].items():
                for index, entry in enumerate(entries, 1):
                    assert 3000 <= entry["duration"] <= 8000
                    assert duration(catalog[category][index]) == entry["duration"]
        else:
            for category in ["morning", "daily", "easterEgg"]:
                for _, entry in catalog[category].items():
                    expected = max(3000, min(8000, 1500 + len(entry.text) * 180))
                    assert duration(entry) == expected, (name, category)
        runtime.execute('''
            local random = math.random
            math.random = function(a,b) return a end
            click(1); advance(100)
            local duration = _testDuration(_testCurrent())
            advance((duration // 100 - 2) * 100)
            check(not clicks[2].obj.flags[lvgl.FLAG.HIDDEN], "dialogue remains before reading deadline")
            advance(200)
            check(clicks[2].obj.flags[lvgl.FLAG.HIDDEN], "dialogue closes at reading deadline")
            click(1); advance(100); click(2); advance(100)
            check(clicks[2].obj.flags[lvgl.FLAG.HIDDEN], "long dialogue can be dismissed early")
            math.random = random
        ''')
        runtime.execute('''
            local random, date = math.random, os.date
            math.random = function(a,b) return a end
            os.date = function() return "8" end
            local function dialogue()
                for _,child in ipairs(clicks[2].obj.children) do
                    if child.text ~= nil then return child.text end
                end
                return clicks[2].obj.children[2].src
            end
            local function greet()
                ScreenStateChangedCB("ON","OFF","test")
                ScreenStateChangedCB("OFF","ON","test")
                return dialogue()
            end
            emit("healthStepCount",0)
            emit("healthHeartRate",0)
            local firstGreeting = greet()
            click(1); advance(100)
            local firstDialogue = dialogue()
            local secondGreeting = greet()
            check(firstGreeting ~= secondGreeting, "greetings exclude previous greeting across clicks")
            click(1); advance(100)
            check(firstDialogue ~= dialogue(), "ordinary dialogue excludes previous dialogue across greetings")
            for i=1,20 do
                local previous = dialogue()
                click(1); advance(100)
                check(previous ~= dialogue(), "consecutive ordinary dialogue does not repeat")
            end
            math.random, os.date = random, date
        ''')
        runtime.execute('''
            local date, random = os.date, math.random
            math.random = function(a,b) return a end
            local hour = "8"
            os.date = function() return hour end
            ScreenStateChangedCB("ON","OFF","test")
            ScreenStateChangedCB("OFF","ON","test")
            advance(8100)
            timerCallbacks = 0
            advance(60000)
            check(timerCallbacks < 30, "idle minute uses event deadlines, not 600 polling callbacks")
            hour = "20"
            advance(60000)
            check(clicks[1].obj.children[1].src:find("bg_n"), "continuous screen updates night theme")
            click(1)
            advance(_testDuration(_testCurrent())); advance(7000)
            ScreenStateChangedCB("ON","OFF","test")
            local callbacks = timerCallbacks
            advance(60000)
            check(timerCallbacks == callbacks, "screen off has no timer callbacks")
            hour = "8"
            ScreenStateChangedCB("OFF","ON","test")
            check(not clicks[1].obj.children[1].src:find("bg_n"), "screen on refreshes theme immediately")
            os.date, math.random = date, random
        ''')
        if not config["imageText"]:
            runtime.execute('''
                local random = math.random
                math.random = function(a,b) if b == 21 then return 7 else return a end end
                local function message()
                    for _,child in ipairs(clicks[2].obj.children) do
                        if child.text ~= nil then return child.text end
                    end
                end
                emit("healthStepCount",11000*256)
                click(1); advance(100)
                check(not message():find("心率"), "missing heart must not select heart dialogue")
                emit("healthHeartRate",120*256)
                click(1); advance(100)
                check(message():find("120"), "valid heart selects heart dialogue")
                emit("healthHeartRate",125*256); advance(100)
                check(message():find("125"), "visible heart dialogue refreshes")
                for _,invalid in ipairs({0,-256,2147483647,250*256}) do
                    emit("healthHeartRate",invalid); advance(100)
                    check(not message():find("心率"), "invalid heart replaces visible dialogue")
                    click(1); advance(100)
                    check(not message():find("心率"), "invalid heart cannot be selected")
                    emit("healthHeartRate",120*256); click(1); advance(100)
                end
                ScreenStateChangedCB("ON","OFF","test")
                advance(300000)
                ScreenStateChangedCB("OFF","ON","test")
                check(not message():find("心率"), "heart expires while screen is off")
                click(1); advance(100)
                check(not message():find("心率"), "expired heart cannot be selected")
                emit("healthHeartRate",100*256); click(1); advance(100)
                check(message():find("100"), "fresh measurement restores heart dialogue")
                emit("healthHeartRate",0)
                math.random = random
            ''')
        runtime.execute('''
            check(#timers == 1, "one animation timer")
            check(lvgl.tick_get == nil, "regression: firmware without tick_get")
            check(subscriptions.timeCentiSecond == nil, "no centisecond redraw subscription")
            for _,key in ipairs({"systemStatusBattery","timeHourHigh","dateMonth","dateWeek"}) do
                emit(key,2147483647)
                emit(key,-256)
                emit(key,99999999)
            end
            for _,battery in ipairs({0,9,10,99,100}) do emit("systemStatusBattery",battery*256) end
            emit("dateMonth",12*256); emit("dateDay",31*256); emit("dateWeek",6*256)
            emit("healthStepCount",11000*256); emit("healthHeartRate",120*256)
            advance(8100)
            check(clicks[2].obj.flags[lvgl.FLAG.HIDDEN], "greeting expires")
            click(1)
            advance(100)
            check(not clicks[2].obj.flags[lvgl.FLAG.HIDDEN], "head tap shows dialogue")
            click(2)
            advance(100)
            check(clicks[2].obj.flags[lvgl.FLAG.HIDDEN], "dialogue tap dismisses")
            advance(11000); advance(500)
            ScreenStateChangedCB("ON","OFF","test")
            check(timers[1].paused, "off pauses timer")
            advance(10000)
            ScreenStateChangedCB("OFF","ON","test")
            check(not timers[1].paused, "on resumes timer")
        ''')
        # Force the rare branch to verify its text resource and timed recovery.
        runtime.execute('''
            math.random=function(a,b) if b==1000 then return 2 elseif b==21 then return 1 else return a end end
            emit("healthStepCount",11000*256)
            click(1); advance(100)
            local background = clicks[1].obj.children[1].src
            check(background == "assets/scare.bin" or background == "assets/scare.png", "rare tap shows scare")
            advance(1100)
            check(not clicks[2].obj.flags[lvgl.FLAG.HIDDEN], "scare returns to dialogue")
            advance(8100)
            check(clicks[2].obj.flags[lvgl.FLAG.HIDDEN], "scare dialogue expires")
        ''')
        runtime.execute('''
            local random, date = math.random, os.date
            os.date = function() return "8" end
            math.random = function(a,b) return a end
            local face, message = clicks[1].obj, clicks[2].obj
            local function wake()
                ScreenStateChangedCB("ON","OFF","test")
                ScreenStateChangedCB("OFF","ON","test")
            end
            emit("healthHeartRate",0)
            wake(); tap(message,screenWidth // 2,380)
            check(_testState() == "idle", "dialogue tap at message box coordinates dismisses")
            tap(face,screenWidth // 2,300)
            check(_testState() == "idle", "mid-screen tap does not trigger head dialogue")
            -- Bubble from an image descendant through the face into the root.
            face.children[1]:add_flag(lvgl.FLAG.EVENT_BUBBLE)
            tap(face.children[1],screenWidth // 2,100)
            check(_testState() == "talking", "descendant tap bubbles to head callback")
            message:add_flag(lvgl.FLAG.EVENT_BUBBLE)
            tap(message,screenWidth // 2,380)
            check(_testState() == "idle", "dialogue bubbling does not reopen dialogue")

            -- A late callback must recover and schedule a future positive deadline.
            tap(face,100,100)
            delayedCallback(5000)
            check(_testState() == "idle", "late dialogue callback recovers")
            check(timers[1].period > 0 and timers[1].due > now, "late callback reschedules forward")

            for _,state in ipairs({"talking","blink","scare"}) do
                wake()
                if state == "blink" then
                    advance(_testDuration(_testCurrent())); advance(7000)
                    check(not face.children[5].flags[lvgl.FLAG.HIDDEN], "interrupt while eye is closed")
                elseif state == "scare" then
                    math.random=function(a,b) if b==1000 then return 2 elseif b==21 then return 1 else return a end end
                    emit("healthStepCount",11000*256); tap(face,100,100)
                    check(_testState() == "scare", "interrupt scare")
                    math.random=function(a,b) return a end
                else
                    check(_testState() == "talking", "interrupt dialogue")
                end
                ScreenStateChangedCB("ON","OFF","test")
                local count=timerCallbacks
                advance(60000)
                check(timerCallbacks == count, "interrupted state has no sleeping callbacks")
                ScreenStateChangedCB("OFF","ON","test")
                check(_testState() == "talking" and not message.flags[lvgl.FLAG.HIDDEN], "wake resets to greeting")
                check(not face.children[2].flags[lvgl.FLAG.HIDDEN], "wake restores time after scare")
            end
            if subscriptions.healthHeartRate then
                emit("healthHeartRate",120*256)
                clockOffset=clockOffset-60
                check(_testValidHeart() == nil, "clock rollback invalidates heart cache")
                emit("healthHeartRate",120*256)
                clockOffset=clockOffset+600
                check(_testValidHeart() == nil, "clock forward expires heart cache")
            end
            clockOffset=0
            tap(face,100,100)
            check(timers[1].period > 0, "clock adjustment keeps valid deadline")
            wake()

            -- Battery tap toggle test
            check(_testScareEnabled() == true, "scare enabled by default")
            -- Tapping head multiple times does NOT toggle scare
            for i=1,10 do
                tap(face,100,100)
                advance(50)
            end
            check(_testScareEnabled() == true, "tapping head never toggles scare")

            -- Tap battery area to toggle scare off
            tap(face,screenWidth // 2,screenHeight - 20)
            check(_testScareEnabled() == false, "tapping battery toggles scare off")
            check(_testCurrent().category == "toggle", "tapping battery shows toggle dialogue")
            -- With scare disabled, 1/1000 chance does NOT trigger scare
            math.random=function(a,b) if b==1000 then return 2 elseif b==21 then return 1 else return a end end
            emit("healthStepCount",11000*256)
            tap(face,100,100)
            check(_testState() ~= "scare", "scare does not trigger when disabled")
            advance(3000)

            -- Tap battery area again to re-enable scare
            tap(face,screenWidth // 2,screenHeight - 20)
            check(_testScareEnabled() == true, "tapping battery re-enables scare")
            advance(3000)
            -- Now scare CAN trigger
            tap(face,100,100)
            check(_testState() == "scare", "scare triggers when re-enabled")
            advance(1100); advance(8100)

            math.random,os.date=random,date
        ''')
        # Enumerate all dynamic digit/week/image-dialogue paths through real setters.
        runtime.execute('''
            for _,key in ipairs({"timeHourHigh","timeHourLow","timeMinuteHigh","timeMinuteLow"}) do
                for value=0,9 do emit(key,value*256) end
            end
            for value=1,31 do emit("dateDay",value*256) end
            for value=1,12 do emit("dateMonth",value*256) end
            for value=0,6 do emit("dateWeek",value*256) end
            for value=0,100 do emit("systemStatusBattery",value*256) end
        ''')
        for category, entries in catalog.items():
            for _, entry in entries.items():
                if entry.image:
                    runtime.globals().validateImage("assets/" + entry.image)
        assert bool(runtime.eval('subscriptions.healthHeartRate ~= nil')) != config["imageText"]
        assert packaged_names <= used_images, (name, "unexercised resource paths", packaged_names - used_images)
        print(f"PASS {name}: Lua 5.4, {len(used_images)} resource paths, data, bubbling, delayed timers, screen lifecycle")


if __name__ == "__main__":
    main()

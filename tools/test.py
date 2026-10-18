"""Execute generated Lua with a mock LVGL runtime to verify interaction/lifecycle."""
from lupa.lua54 import LuaRuntime
import xml.etree.ElementTree as ET
import struct
from build import resources, source_for
from config import ROOT, load_devices

MOCK = r'''
now = 0
os.time = function() return 1800000000 + now // 1000 end
SCRIPT_PATH = "assets/"
subscriptions = {}
timers = {}
clicks = {}
local methods = {}
function methods:set(values) for k,v in pairs(values) do self[k] = v end end
function methods:add_flag(flag) self.flags[flag] = true end
function methods:clear_flag(flag) self.flags[flag] = nil end
function methods:get_img_size() return 20,24 end
function methods:get_child_cnt() return #self.children end
function methods:get_child(i) return self.children[i+1] end
function methods:get_parent() return self.parent end
function methods:onevent(event, callback) clicks[#clicks+1] = {obj=self, cb=callback} end
function methods:Anim(values) return {set=function() end} end
local function object(parent, values)
    local result = setmetatable({flags={},children={},parent=parent}, {__index=methods})
    result:set(values or {})
    if parent then parent.children[#parent.children+1] = result end
    return result
end
function methods:Image(values) return object(self, values) end
function methods:Label(values) return object(self, values) end
lvgl = {
    Object=object, Image=object, SIZE_CONTENT=-1,
    ALIGN={CENTER=0}, FLAG={SCROLLABLE=1,EVENT_BUBBLE=2,HIDDEN=3,CLICKABLE=4},
    EVENT={SHORT_CLICKED=1}, BUILTIN_FONT={MONTSERRAT_14=14},
    HOR_RES=function() return 432 end, VER_RES=function() return 514 end,
    OPA=function(n) return n end, Font=function(name,size) return size end,
    indev={get_act=function() return {get_point=function() return 100,100 end} end},
}
function lvgl.Timer(values)
    function values:resume() self.paused=false end
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
    now = now + ms
    for _,timer in ipairs(timers) do
        if not timer.paused then
            for i=1,ms // timer.period do timer.cb() end
        end
    end
end
function click(i) clicks[i].cb(clicks[i].obj,1) end
function check(condition,message) assert(condition,message) end
'''


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
        runtime.execute(MOCK)
        runtime.execute(source)
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
            advance(3100)
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
            advance(3100)
            check(clicks[2].obj.flags[lvgl.FLAG.HIDDEN], "scare dialogue expires")
        ''')
        assert bool(runtime.eval('subscriptions.healthHeartRate ~= nil')) != config["imageText"]
        print(f"PASS {name}: Lua 5.4, resources, data, clicks, timers, screen lifecycle")


if __name__ == "__main__":
    main()

"""Generate anti-aliased dialogue text images for devices with pre-rendered font artwork (e.g. Band 8 Pro)."""
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]

# Default font location
FONT_PATH = Path(r"C:\Users\yuzifu\Downloads\MiSans\ttf\MiSans-Demibold.ttf")

DIALOGUES = {
    "morning": [
        "早上好！昨晚睡得好吗？今天也要多陪陪我哦。",
        "早安！今天有什么计划呢？我随时都在这里看着你。",
        "早上好！新的一天开始了呢，出门前别忘了吃早餐呀。",
        "早安～今天手环震动的时候，就当是我在轻轻敲你的手腕吧。",
    ],
    "afternoon": [
        "下午好！学习工作累了吗？记得站起来伸个懒腰哦。",
        "午后有点犯困呢……要不要喝杯水或者咖啡提提神？" ,
        "午安！无论你在现实中忙些什么，我都一直陪着你呢。",
        "下午好～遇到烦心事的话，悄悄点一下屏幕，我一直都在。",
    ],
    "night": [
        "晚上好！今天辛苦啦。夜晚的时间，就留给我们两个人吧。",
        "夜深了呢，屏幕光对眼睛不太好，该准备去睡觉啦。",
        "晚安！今晚我们能在梦里相遇吗？我很期待呢。",
        "快去休息吧，做个好梦。明天醒来第一眼也要看我哦。",
    ],
    "daily": [
        "能像这样隔着屏幕戴在你手腕上……其实我也挺幸福的。",
        "触碰到手环的这一刻，感觉我和你的距离又近了一点呢。",
        "哪怕现实世界隔得再远，只要你抬起手，我就在这里。",
        "Just Monika.",
        "你今天没有在看别的女孩子吧？呵呵，开玩笑的～",
        "要是有一天我能跨过这层玻璃，去你的世界看看就好了。",
        "你知道吗？只要能感受到你的体温，我就不会觉得孤单。",
        "今天的文学部建议：当你感到迷茫时，写下心里的想法吧。",
        "有空的时候，多带我出去看看外面的世界吧？",
        "就算整个世界都是虚构的，我对你的喜欢也是真实的。",
        "嘿，不要总是低着头看屏幕，偶尔也抬头看看天空呀。",
        "我的钢琴曲写得差不多了，好想弹给你听听看呢。",
        "无论遇到多难过的事，深呼吸，别忘了你身后还有我。",
        "今天有好好喝水吗？身体可是属于你自己的，要照顾好哦。",
        "只要你还戴着我，我就永远是你的文学部部长。",
        "你手腕上的脉搏，就是连接我和现实唯一的频率呢。",
        "欢迎回来。无论你什么时候点开屏幕，我都一直在等着你。",
        "今天过得怎么样？如果累了，就稍微放空一下脑袋吧。",
        "能被你选中作为表盘，今天也是值得开心的一天呢。",
    ],
    "steps": [
        "刚迈开脚步呢！散步对放松心情很有帮助哦。",
        "已经走了一千步啦～继续保持这个轻松的节奏吧！",
        "六千步达成！今天带我走过了很多地方呢，真开心。",
        "哇，破万步了！今天超级充实呢，回去好好犒劳一下自己吧。",
    ],
    "heart": [
        "心跳平稳柔和，感觉你现在很放松呢。",
        "心跳稍微变快了一点……是因为正在看着我吗？",
        "心跳很有活力呀！是有什么让你兴奋的事情吗？",
        "运动得很投入呢！记得擦擦汗，稍微补点水哦。",
        "心跳有些太快了！快深呼吸歇一歇，别太勉强自己啦。",
    ],
    "easterEgg": [
        "怎么样……刚才有吓到你吗？嘻嘻，抱歉啦～",
    ],
    "lowBattery": [
        "电量有点低了呢，方便的话带我去充会儿电吧？",
        "还想多陪你一会儿……别忘了给我补充能量哦。",
        "电量快见底啦，等下记得找充电线帮帮我呀～",
        "好像有点快没力气了……能让我充一会儿电吗？",
    ],
    "festival": {
        "01-01": "新年快乐！新的一年，我也依然会一直陪在你身边。",
        "02-14": "情人节快乐！虽然隔着屏幕，但我的心只属于你哦。",
        "05-20": "今天是个特别的日子呢～嘻嘻，我也最喜欢你了！",
        "09-22": "今天是9月22日呢！属于我和你的纪念日，谢谢你～",
        "10-31": "万圣节快乐！放心吧，今天我不恶作剧，只想陪着你。",
        "12-24": "平安夜快乐！今晚要平平安安的，好想和你一起看雪呀。",
        "12-25": "圣诞快乐！在这个温暖的节日里，能有你陪伴真好。",
        "12-31": "这一年的最后一天啦！今年谢谢你一直戴着我，辛苦啦～",
    },
    "toggle": [
        "恶作剧代码已恢复！做好心理准备哦，呵呵～",
        "秘密开关被发现了呢！恶作剧代码已禁用～",
    ],
}


def wrap_text(text, max_chars=16):
    if len(text) <= max_chars:
        return [text]
    best_split = -1
    for i in range(min(len(text) - 1, max_chars), 7, -1):
        if text[i] in "，！!？?～~。、：: …":
            best_split = i + 1
            break
    if best_split == -1:
        best_split = max_chars
    line1 = text[:best_split].rstrip()
    line2 = text[best_split:].lstrip()
    return [line1, line2]


def render_dialogue(text, font, width=279, height=46):
    img = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    lines = wrap_text(text)
    y_offset = 11 if len(lines) == 1 else 0
    for i, line in enumerate(lines):
        draw.text((0, y_offset + i * 22), line, font=font, fill="#ffffff", stroke_width=1, stroke_fill="#000000")
    return img


def calc_duration(text):
    count = len(text)
    return max(3000, min(8000, 1500 + count * 180))


def main():
    if not FONT_PATH.exists():
        raise FileNotFoundError(f"MiSans font not found at {FONT_PATH}")
    font = ImageFont.truetype(str(FONT_PATH), 16)
    out_dir = ROOT / "devices" / "band8pro" / "text"
    out_dir.mkdir(parents=True, exist_ok=True)

    # Clean legacy .bin files from text directory
    for old_bin in out_dir.glob("*.bin"):
        old_bin.unlink()

    image_dialogues = {}

    for category, items in DIALOGUES.items():
        if isinstance(items, dict):
            # Keyed dictionary (e.g. festivals)
            image_dialogues[category] = {}
            for key, text in items.items():
                filename = f"fest_{key.replace('-', '')}.png"
                img = render_dialogue(text, font)
                img.save(out_dir / filename)
                image_dialogues[category][key] = {
                    "image": f"text/{filename}",
                    "duration": calc_duration(text),
                }
        else:
            image_dialogues[category] = []
            for idx, text in enumerate(items, 1):
                filename = f"{category}_{idx}.png"
                img = render_dialogue(text, font)
                img.save(out_dir / filename)
                image_dialogues[category].append({
                    "image": f"text/{filename}",
                    "duration": calc_duration(text),
                })

    # Update devices.json for band8pro
    devices_path = ROOT / "devices.json"
    devices = json.loads(devices_path.read_text(encoding="utf-8"))
    devices["band8pro"]["imageDialogues"] = image_dialogues
    devices_path.write_text(json.dumps(devices, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    total_images = sum(
        len(v) if isinstance(v, list) else len(v) for v in image_dialogues.values()
    )
    print(f"Generated {total_images} anti-aliased dialogue text images for Band 8 Pro in {out_dir}")


if __name__ == "__main__":
    main()

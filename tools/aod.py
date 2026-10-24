"""Generate native EasyFace AOD widgets; no Lua is included in this screen."""
import shutil
import xml.etree.ElementTree as ET
from PIL import Image
from aod_drafts import outline
from config import ROOT


def generate(config, assets, output):
    folder = output / "AOD"
    images = folder / "images"
    images.mkdir(parents=True, exist_ok=True)
    family = "large" if config["assets"] in ("redmiwatch6", "s4", "s5_46") else "common"
    for path in (ROOT / "assets/aod" / family).glob("*.png"):
        shutil.copyfile(path, images / path.name)
    outline(assets["ap.bin"]).save(images / "ap.png")
    # Use the approved AOD draft as the editor/compilation preview.
    # Rendering is performed by build.py once, outside this function.
    draft = ROOT / "build/aod-drafts" / config.get("packageAlias", config.get("target", config["assets"])) / "preview.png"
    if not draft.exists(): draft = ROOT / "build/aod-drafts" / config["assets"] / "preview.png"
    with Image.open(draft) as preview:
        preview.resize(tuple(config.get("previewSize", [config["width"], config["height"]])), Image.Resampling.LANCZOS).save(folder / "preview.png")
    shutil.copyfile(folder / "preview.png", images / "preview.png")
    (folder / "output").mkdir(exist_ok=True)
    project = ET.Element("FaceProject", DeviceType=str(config["deviceType"]))
    screen = ET.SubElement(project, "Screen", Title="莫妮卡 AOD", Bitmap="preview.png")
    digits = "|".join([*(f"{i}.png" for i in range(10)), "0.png"])
    small = "|".join([*(f"num{i}.png" for i in range(10)), "num0.png"])

    def widget(name, x, y, bitmap=None, source=None, count=1, spacing=0):
        image = bitmap or ("0.png" if name.startswith("time") else "num0.png")
        with Image.open(images / image) as im: width, height = im.size
        attrs = dict(Shape="30" if source is None else "32", Name=name, X=str(x), Y=str(y),
                     Width=str(width), Height=str(height), Alpha="255", Visible_Src="0")
        if source is None: attrs["Bitmap"] = bitmap
        else:
            attrs.update(Digits=str(count), Alignment="1", Spacing=str(spacing), Blanking="1" if count>1 else "0",
                         Value_Src=str(source), BitmapList=digits if name.startswith("time") else small)
        return ET.SubElement(screen, "Widget", **attrs)

    sources = {"timeHourHigh":1000911,"timeHourLow":911,"timeMinuteHigh":1211,"timeMinuteLow":1111,
               "dateContChild1":1212,"dateContChild2":1112,"dateContChild4":1001912,"dateContChild5":1912}
    for group in config["layout"]["groups"]:
        name = group["name"]
        if name == "msg": continue
        x,y = group["x"], group["y"]
        if name == "time": y=config["timeY"]
        elif name == "dateCont": y=config["dateY"]
        if name == "chargeCont":
            # Native numeric widget handles leading blanking. Percent is behind digits.
            positions=config["layout"]["battery"][2]
            widget("batteryPercent",x+positions[4],y,bitmap="num%.png")
            step=positions[2]-positions[1]
            with Image.open(images/"num0.png") as im: width=im.width
            widget("battery",x+positions[1],y,source=841,count=3,spacing=step-width)
            widget("batteryIcon",x+positions[0],y+group["children"][0].get("y",0),bitmap="ap.png")
            continue
        for child in group["children"]:
            field=child["name"]
            if field=="dateWeek":
                with Image.open(images/"mon.png") as im: w,h=im.size
                ET.SubElement(screen,"Widget",Shape="31",Name=field,X=str(x+child["x"]),Y=str(y+child.get("y",0)),
                              Width=str(w),Height=str(h),Alpha="255",Visible_Src="0",Index_Src="2012",DefaultIndex="1",
                              BitmapList="|".join(f"({i}):{day}.png" for i,day in enumerate(["sun","mon","tue","wed","thu","fri","sat"])))
            else:
                widget(field,x+child.get("x",0),y+child.get("y",0),
                       bitmap=child["image"].replace(".bin",".png") if field not in sources else None,source=sources.get(field))
    path=folder/"monika.fprj"
    ET.ElementTree(project).write(path,encoding="utf-16",xml_declaration=True)
    return path

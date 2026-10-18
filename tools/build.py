"""Generate device-specific EasyFace projects and optionally compile watchface packages."""
import argparse
import json
import re
import shutil
import struct
import subprocess
import xml.etree.ElementTree as ET
from pathlib import Path

from config import ROOT, load_devices


def lua(value):
    if isinstance(value, dict):
        return "{" + ",".join(f"{key}={lua(item)}" for key, item in value.items()) + "}"
    if isinstance(value, list):
        return "{" + ",".join(map(lua, value)) + "}"
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, str):
        return json.dumps(value, ensure_ascii=False)
    return str(value)


def source_for(config):
    common = (ROOT / "src/common.lua").read_text(encoding="utf-8")
    layout = (ROOT / "devices" / config["assets"] / "layout.lua").read_text(encoding="utf-8")
    layout = layout.replace("os.clock()", "lvgl.tick_get()")
    layout = layout.replace(f"w = {config['width']},", "w = DEVICE.width,", 1)
    layout = layout.replace(f"h = {config['height']},", "h = DEVICE.height,", 1)
    # Keep callbacks from old releases local to their invocation.
    layout = layout.replace('            src = ', '            local src = ')
    layout = layout.replace('if (y <= 225', 'if (y <= DEVICE.touchMaxY')
    subscriptions = (ROOT / "src/subscriptions.lua").read_text(encoding="utf-8")
    if config["imageText"]:
        subscriptions = subscriptions[:subscriptions.index("    -- 步数和心率")]
    subscriptions = re.sub(r"(?m)^(\s*)(src|index|str) =", r"\1local \2 =", subscriptions)
    # dateWeek increments an existing local rather than declaring another value.
    subscriptions = subscriptions.replace("local index = index + 1", "index = index + 1")
    runtime = (ROOT / "src/runtime.lua").read_text(encoding="utf-8").replace("    -- BUILD_SUBSCRIPTIONS", subscriptions)
    source = "local DEVICE = " + lua(config) + "\n" + common + "\n" + layout + "\n" + runtime
    # Resolve both literal and dynamically constructed legacy filenames in imgPath.
    mapping = {name: name.removesuffix(".bin") + ".png"
               for name, path in resources(config).items() if path.suffix == ".png"}
    source = source.replace("local function imgPath(name) return fsRoot .. name end",
                            "local PNG_ASSETS = {" + ",".join(f"[{lua(key)}]={lua(value)}" for key, value in mapping.items()) + "}" +
                            "\nlocal function imgPath(name) return fsRoot .. (PNG_ASSETS[name] or name) end")
    return source


def resources(config, source=None):
    folder = ROOT / "devices" / config["assets"]
    assets = {path.relative_to(folder).as_posix(): path for path in folder.rglob("*.bin")}
    for path in (ROOT / "assets/common").glob("*.png"):
        assets[path.stem + ".bin"] = path
    for path in (folder / "originals").glob("*.png"):
        assets[path.stem + ".bin"] = path
    required = {f"{i}.bin" for i in range(10)} | {f"num{i}.bin" for i in range(10)}
    required.update(["bg.bin", "bg_n.bin", "eye_close.bin", "eye_close_n.bin", "smile.bin", "smile_n.bin",
                     "scare.bin", "msg.bin", "ap.bin", "num%.bin", "num_mao.bin", "num_gang.bin",
                     "sun.bin", "mon.bin", "tue.bin", "wed.bin", "thu.bin", "fri.bin", "sat.bin"])
    if config["imageText"]:
        required.update(f"text/text{i}.bin" for i in range(1, 22))
    missing = required - assets.keys()
    if missing:
        raise FileNotFoundError(f"{config['assets']}: missing {sorted(missing)}")
    if any(not assets[name].stat().st_size for name in required):
        raise ValueError("Empty image resource")
    if not (folder / "preview.png").is_file():
        raise FileNotFoundError(folder / "preview.png")
    return {name: assets[name] for name in sorted(required)}


def patch_metadata(path, face_id, version):
    data = bytearray(path.read_bytes())
    if len(data) < 168 or data[:4] != b"\x5a\xa5\x34\x12":
        raise ValueError("Unexpected Gen2 package header")
    data[40:58] = face_id.encode("ascii").ljust(18, b"\0")
    struct.pack_into("<I", data, 4, version)
    path.write_bytes(data)


def main():
    devices = load_devices()
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--device", choices=["all", *devices], default="all")
    parser.add_argument("--compiler", type=Path)
    parser.add_argument("--id", default="979825266001")
    parser.add_argument("--version", type=int, default=2)
    args = parser.parse_args()
    if not re.fullmatch(r"(?:[0-9]{9}|[0-9]{12})", args.id) or not 0 <= args.version <= 0xFFFFFFFF:
        parser.error("ID must be 9 or 12 ASCII digits; version must fit UInt32")
    selected = devices[args.device].get("packageAlias", args.device) if args.device != "all" else "all"
    targets = {name: config for name, config in devices.items() if not config.get("packageAlias") and selected in ("all", name)}
    prepared = {}
    for name, config in targets.items():
        source = source_for(config)
        prepared[name] = (source, resources(config, source))
    for name, config in targets.items():
        source, assets = prepared[name]
        output = ROOT / "build" / name
        app = output / "app/_lua/monika"
        if (output / "app").exists():
            shutil.rmtree(output / "app")
        app.mkdir(parents=True, exist_ok=True)
        for relative, asset in assets.items():
            if asset.suffix == ".png":
                relative = str(Path(relative).with_suffix(".png"))
            destination = app / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(asset, destination)
        (app / "monika.lua").write_text(source, encoding="utf-8")
        shutil.copyfile(ROOT / "devices" / config["assets"] / "preview.png", output / "preview.png")
        project = ET.Element("FaceProject", DeviceType=str(config["deviceType"]))
        screen = ET.SubElement(project, "Screen", Title="莫妮卡", Bitmap="preview.png")
        ET.SubElement(screen, "Widget", Shape="34", Name="app__lua%2Fmonika%2Fmonika.lua", X="0", Y="0",
                      Width=str(config["width"]), Height=str(config["height"]), Alpha="0", Visible_Src="0")
        path = output / "monika.fprj"
        ET.ElementTree(project).write(path, encoding="utf-16", xml_declaration=True)
        print(f"{name}: {path}")
        if args.compiler:
            staging = output / "compiled"
            staging.mkdir(exist_ok=True)
            fresh = staging / f"monika-{name}.face"
            fresh.unlink(missing_ok=True)
            subprocess.run([str(args.compiler.resolve()), "-b", str(path), str(staging), fresh.name, "252661004"], check=True)
            patch_metadata(fresh, args.id, args.version)
            dist = ROOT / "dist"
            dist.mkdir(exist_ok=True)
            shutil.copyfile(fresh, dist / fresh.name)
            for alias, entry in devices.items():
                if entry.get("packageAlias") == name:
                    shutil.copyfile(fresh, dist / f"monika-{alias}.face")
    for name, config in devices.items():
        if config.get("packageAlias") and selected in ("all", config["packageAlias"]):
            print(f"{name}: uses {config['packageAlias']} project/package")


if __name__ == "__main__":
    main()

"""Generate the canonical daylight preview with antialiased screen corners."""
import argparse
from pathlib import Path

from PIL import Image, ImageDraw
from config import ROOT, load_devices


def generate(config, assets, output=None):
    width, height = config["width"], config["height"]
    def load(name):
        with Image.open(assets[name]) as source:
            return source.convert("RGBA")

    canvas = load("bg.bin")
    if canvas.size != (width, height):
        raise ValueError(f"Background size mismatch: {canvas.size}")
    replacements = {
        "timeHourHigh": "0.bin", "timeHourLow": "8.bin",
        "timeMinuteHigh": "4.bin", "timeMinuteLow": "5.bin",
        "dateContChild1": "num0.bin", "dateContChild2": "num9.bin",
        "dateContChild4": "num2.bin", "dateContChild5": "num2.bin",
        "dateWeek": "mon.bin",
    }
    def paste(name, x, y):
        canvas.alpha_composite(load(name), (x, y))

    for group in config["layout"]["groups"]:
        if group["name"] == "msg": continue
        x, y = group["x"], group["y"]
        if group["name"] == "time": y = config["timeY"]
        elif group["name"] == "dateCont": y = config["dateY"]
        if group["name"] == "chargeCont":
            positions = config["layout"]["battery"][1]
            icon = group["children"][0]
            for i, name in reversed(list(enumerate(["num9.bin", "num9.bin", "num%.bin"], 1))):
                paste(name, x + positions[i], y)
            paste("ap.bin", x + positions[0], y + icon.get("y", 0))
            continue
        for child in group["children"]:
            paste(replacements.get(child["name"], child["image"]),
                  x + child.get("x", 0), y + child.get("y", 0))

    shape = config["previewShape"]
    factor = 4
    mask = Image.new("L", (width * factor, height * factor), 0)
    bounds = (0, 0, width * factor - 1, height * factor - 1)
    draw = ImageDraw.Draw(mask)
    if shape == "circle":
        draw.ellipse(bounds, fill=255)
    else:
        radius = width / 2 if shape == "capsule" else shape
        draw.rounded_rectangle(bounds, radius=round(radius * factor), fill=255)
    canvas.putalpha(mask.resize((width, height), Image.Resampling.LANCZOS))
    destination = ROOT / "devices" / config["assets"] / "preview.png"
    canvas.save(destination)
    # Remove only outputs of the previous preview implementation.
    if output is not None:
        old = Path(output)
        for filename in ["normal.png", "night.png", "diagnostics.json"]:
            (old / filename).unlink(missing_ok=True)
        if old.is_dir() and not any(old.iterdir()): old.rmdir()
    return destination


def main():
    from build import resources
    devices = load_devices()
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--device", choices=["all", *devices], default="all")
    args = parser.parse_args()
    seen = set()
    for name, config in devices.items():
        if args.device not in ("all", name): continue
        old = ROOT / "build" / name / "previews"
        # Aliases share the same artwork and canonical preview.
        if config["assets"] not in seen:
            print(f"{name}: {generate(config, resources(config), old)}")
            seen.add(config["assets"])
        else:
            for filename in ["normal.png", "night.png", "diagnostics.json"]:
                (old / filename).unlink(missing_ok=True)
            if old.is_dir() and not any(old.iterdir()): old.rmdir()


if __name__ == "__main__":
    main()

"""Import author's PNG exports under stable watchface resource names."""
import json
import shutil
from pathlib import Path

from config import ROOT

RW6 = Path(r"C:\Users\yuzifu\Downloads\download")
COMMON = Path(r"C:\Users\yuzifu\Downloads\download (1)")


def main():
    mapping = {"ap@1x.png": "ap.png"}
    for number, digit in zip(range(178, 188), [0, 1, 2, 3, 4, 5, 8, 7, 6, 9]):
        mapping[f"容器 {number}@1x.png"] = f"{digit}.png"
    for number, name in zip(range(198, 211), [
        "num0", "num1", "num2", "num3", "num4", "num5", "num6", "num7",
        "num9", "num%", "num_gang", "num8", "num_mao",
    ]):
        mapping[f"容器 {number}@1x.png"] = name + ".png"
    for number, name in zip([211, 212, 213, 214, 215, 216, 218], ["mon", "tue", "wed", "thu", "fri", "sun", "sat"]):
        mapping[f"容器 {number}@1x.png"] = name + ".png"
    destination = ROOT / "assets/common"
    destination.mkdir(parents=True, exist_ok=True)
    for original, renamed in mapping.items():
        shutil.copyfile(COMMON / original, destination / renamed)
    (destination / "source-map.json").write_text(json.dumps(mapping, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    for asset in RW6.glob("*.png"):
        shutil.copyfile(asset, ROOT / "devices/redmiwatch6/originals" / asset.name)
    print(f"Imported {len(mapping)} common PNGs and {len(list(RW6.glob('*.png')))} RW6 PNGs")


if __name__ == "__main__":
    main()

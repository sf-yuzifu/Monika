"""Remove binary artwork superseded by the selected PNG source."""
import shutil

from build import resources
from config import ROOT, load_devices


def main():
    removed = 0
    saved = 0
    seen = set()
    for config in load_devices().values():
        folder = ROOT / "devices" / config["assets"]
        if folder in seen:
            continue
        seen.add(folder)
        for name, selected in resources(config).items():
            binary = folder / name
            if selected.suffix == ".png" and binary.is_file():
                saved += binary.stat().st_size
                binary.unlink()
                removed += 1
    # Preserve the standalone legacy Band 9 project with local PNG copies.
    legacy = ROOT / "app/_lua/monika"
    for png in sorted((ROOT / "assets/common").glob("*.png")):
        binary = legacy / (png.stem + ".bin")
        if binary.is_file():
            shutil.copyfile(png, legacy / png.name)
            saved += binary.stat().st_size
            binary.unlink()
            removed += 1
    print(f"Removed {removed} superseded BIN files ({saved:,} bytes)")


if __name__ == "__main__":
    main()

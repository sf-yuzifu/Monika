"""Remove binary artwork superseded by the selected PNG source."""
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
    print(f"Removed {removed} superseded BIN files ({saved:,} bytes)")


if __name__ == "__main__":
    main()

"""Validate a release tag and read the package version from the AstroBox manifest."""
import argparse
import json
import re
from pathlib import Path

DEFAULT_MANIFEST = Path(__file__).resolve().parents[1] / "manifest_v2.json"


def version_code(tag, manifest_path=DEFAULT_MANIFEST):
    match = re.fullmatch(r"v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)", tag)
    if not match:
        raise ValueError("Use a stable version tag such as v1.2.3")
    manifest = json.loads(Path(manifest_path).read_text(encoding="utf-8"))
    downloads = manifest.get("downloads")
    if not isinstance(downloads, dict) or not downloads:
        raise ValueError("manifest_v2.json must contain nonempty downloads")
    codes = set()
    for device, entry in downloads.items():
        if not isinstance(entry, dict): raise ValueError(f"Invalid download entry: {device}")
        code = entry.get("versionCode")
        if type(code) is not int or not 0 < code <= 0xFFFFFFFF:
            raise ValueError(f"{device}: versionCode must be a positive UInt32 integer")
        codes.add(code)
    if len(codes) != 1:
        raise ValueError("All download entries must have the same versionCode")
    return codes.pop()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("tag")
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    args = parser.parse_args()
    try:
        print(version_code(args.tag, args.manifest))
    except ValueError as error:
        parser.error(str(error))

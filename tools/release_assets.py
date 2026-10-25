"""Verify fresh interactive build outputs before uploading GitHub Release assets."""
import argparse
import hashlib
import struct
from pathlib import Path
from config import ROOT, load_devices


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--version", required=True, type=int)
    parser.add_argument("--dist", type=Path, default=ROOT / "dist")
    args = parser.parse_args()
    output = args.dist
    expected = {f"monika-{name}.face" for name in load_devices()}
    actual = {path.name for path in output.glob("*.face")}
    if actual != expected:
        raise ValueError(f"Unexpected release files: missing={expected-actual}, extra={actual-expected}")
    checksums = []
    for name in sorted(expected):
        data = (output / name).read_bytes()
        if len(data) < 168 or data[:4] != b"\x5a\xa5\x34\x12": raise ValueError(name)
        if struct.unpack_from("<I", data, 4)[0] != args.version: raise ValueError(f"Version mismatch: {name}")
        if data[40:58].split(b"\0", 1)[0] != b"979825266001": raise ValueError(f"ID mismatch: {name}")
        if b"selectDialogue" not in data: raise ValueError(f"Interactive Lua missing: {name}")
        checksums.append(f"{hashlib.sha256(data).hexdigest()}  {name}")
    for name, config in load_devices().items():
        if config.get("packageAlias"):
            assert (output / f"monika-{name}.face").read_bytes() == (output / f"monika-{config['packageAlias']}.face").read_bytes()
    (output / "SHA256SUMS.txt").write_text("\n".join(checksums)+"\n", encoding="utf-8")
    print(f"Verified {len(expected)} interactive packages, version {args.version}")


if __name__ == "__main__": main()

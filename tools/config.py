"""Resolve device inheritance and package aliases."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def load_devices():
    raw = json.loads((ROOT / "devices.json").read_text(encoding="utf-8"))
    resolved = {}

    def resolve(name, stack=()):
        if name in stack:
            raise ValueError(f"Device inheritance cycle: {stack + (name,)}")
        if name in resolved:
            return resolved[name]
        entry = raw[name]
        parent = entry.get("extends") or entry.get("packageAlias")
        config = dict(resolve(parent, stack + (name,))) if parent else {}
        config.pop("packageAlias", None)
        config.update({key: value for key, value in entry.items() if key != "extends"})
        resolved[name] = config
        return config

    return {name: resolve(name) for name in raw}

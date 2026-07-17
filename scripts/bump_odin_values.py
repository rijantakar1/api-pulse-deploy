#!/usr/bin/env python3
"""Bump charts/odin/values.yaml images.<api|ui>.tag

Usage: bump_odin_values.py <values.yaml> <api|ui> <image_tag>
"""
from __future__ import annotations

import sys
from pathlib import Path


def bump(path: Path, key: str, tag: str) -> None:
    if key not in {"api", "ui"}:
        raise SystemExit(f"unknown key: {key}")
    lines = path.read_text().splitlines(keepends=True)
    out: list[str] = []
    in_images = False
    in_svc = False
    updated = False
    for line in lines:
        # Strip trailing newline so endswith(":") works (same bug as bump_values.py).
        raw = line.rstrip("\r\n")
        stripped = raw.lstrip()
        indent = len(raw) - len(stripped)
        if stripped.startswith("images:"):
            in_images = True
            in_svc = False
            out.append(line)
            continue
        if indent == 0 and stripped and not stripped.startswith("#") and not stripped.startswith(
            "images:"
        ):
            in_images = False
            in_svc = False
        if in_images and indent == 2 and stripped.startswith(f"{key}:"):
            in_svc = True
            out.append(line)
            continue
        if in_images and indent == 2 and stripped.endswith(":") and not stripped.startswith(f"{key}:"):
            in_svc = False
        if in_images and in_svc and indent >= 4 and stripped.startswith("tag:"):
            out.append(f"{' ' * indent}tag: {tag}\n")
            updated = True
            continue
        out.append(line)
    if not updated:
        raise SystemExit(f"failed to update images.{key}.tag")
    path.write_text("".join(out))
    print(f"Updated images.{key}.tag -> {tag}")


if __name__ == "__main__":
    if len(sys.argv) != 4:
        raise SystemExit("usage: bump_odin_values.py <values.yaml> <api|ui> <image_tag>")
    bump(Path(sys.argv[1]), sys.argv[2], sys.argv[3])

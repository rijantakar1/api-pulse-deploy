#!/usr/bin/env python3
"""Update charts/api-pulse/values.yaml image tag, versions, and versionsActive.

Usage: bump_values.py <values.yaml> <service_key> <image_tag>
  service_key: web | auth | analytics

Appends tag to versionsActive.<service> (newest last), trims to versionsActiveMax.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path


def bump(path: Path, service_key: str, tag: str) -> None:
    if service_key not in {"web", "auth", "analytics"}:
        raise SystemExit(f"unknown service_key: {service_key}")

    version_key = "ui" if service_key == "web" else service_key
    text = path.read_text()
    lines = text.splitlines(keepends=True)

    max_m = re.search(r"^versionsActiveMax:\s*(\d+)\s*$", text, re.M)
    max_keep = int(max_m.group(1)) if max_m else 5

    out: list[str] = []
    in_images = False
    in_service = False
    in_versions = False
    in_versions_active = False
    updated_image = False
    updated_version = False
    updated_active = False

    i = 0
    while i < len(lines):
        line = lines[i]
        stripped = line.lstrip()
        indent = len(line) - len(stripped)

        if stripped.startswith("images:"):
            in_images = True
            in_versions = False
            in_versions_active = False
            in_service = False
            out.append(line)
            i += 1
            continue
        if stripped.startswith("versionsActive:"):
            in_versions_active = True
            in_images = False
            in_versions = False
            in_service = False
            out.append(line)
            i += 1
            continue
        if stripped.startswith("versions:") and not stripped.startswith("versionsActive"):
            in_versions = True
            in_images = False
            in_versions_active = False
            in_service = False
            out.append(line)
            i += 1
            continue
        if indent == 0 and stripped and not stripped.startswith("#"):
            if not (
                stripped.startswith("images:")
                or stripped.startswith("versions:")
                or stripped.startswith("versionsActive")
            ):
                in_images = False
                in_versions = False
                in_versions_active = False
            in_service = False

        if in_images and indent == 2 and stripped.startswith(f"{service_key}:"):
            in_service = True
            out.append(line)
            i += 1
            continue
        if in_images and indent == 2 and stripped.endswith(":") and not stripped.startswith(
            f"{service_key}:"
        ):
            in_service = False

        if in_images and in_service and indent >= 4 and stripped.startswith("tag:"):
            out.append(f"{' ' * indent}tag: {tag}\n")
            updated_image = True
            i += 1
            continue

        if in_versions and indent == 2 and stripped.startswith(f"{version_key}:"):
            out.append(f"{' ' * indent}{version_key}: \"{tag}\"\n")
            updated_version = True
            i += 1
            continue

        if in_versions_active and indent == 2 and stripped.startswith(f"{service_key}:"):
            out.append(line)
            i += 1
            items: list[str] = []
            while i < len(lines):
                item_line = lines[i]
                item_stripped = item_line.lstrip()
                if item_stripped.startswith("- "):
                    raw = item_stripped[2:].strip().strip('"').strip("'")
                    items.append(raw)
                    i += 1
                    continue
                break
            items = [t for t in items if t != tag]
            items.append(tag)
            items = items[-max_keep:]
            for t in items:
                out.append(f'    - "{t}"\n')
            updated_active = True
            continue

        out.append(line)
        i += 1

    if not updated_image:
        raise SystemExit(f"failed to update images.{service_key}.tag")
    if not updated_version:
        raise SystemExit(f"failed to update versions.{version_key}")
    if not updated_active:
        raise SystemExit(f"failed to update versionsActive.{service_key}")

    path.write_text("".join(out))
    print(
        f"Updated images.{service_key}.tag, versions.{version_key}, "
        f"versionsActive.{service_key} -> {tag}"
    )


if __name__ == "__main__":
    if len(sys.argv) != 4:
        raise SystemExit("usage: bump_values.py <values.yaml> <service_key> <image_tag>")
    bump(Path(sys.argv[1]), sys.argv[2], sys.argv[3])

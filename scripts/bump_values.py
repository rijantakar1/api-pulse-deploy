#!/usr/bin/env python3
"""Update charts/api-pulse/values.yaml image tag + versions for one service.

Usage: bump_values.py <values.yaml> <service_key> <image_tag>
  service_key: web | auth | analytics
"""
from __future__ import annotations

import sys
from pathlib import Path


def bump(path: Path, service_key: str, tag: str) -> None:
    if service_key not in {"web", "auth", "analytics"}:
        raise SystemExit(f"unknown service_key: {service_key}")

    version_key = "ui" if service_key == "web" else service_key
    lines = path.read_text().splitlines(keepends=True)
    out: list[str] = []
    in_images = False
    in_service = False
    in_versions = False
    updated_image = False
    updated_version = False

    for line in lines:
        stripped = line.lstrip()
        indent = len(line) - len(stripped)

        if stripped.startswith("images:"):
            in_images = True
            in_versions = False
            in_service = False
            out.append(line)
            continue
        if stripped.startswith("versions:"):
            in_versions = True
            in_images = False
            in_service = False
            out.append(line)
            continue
        if indent == 0 and stripped and not stripped.startswith("#"):
            # top-level key
            if not stripped.startswith("images:") and not stripped.startswith("versions:"):
                if in_images or in_versions:
                    in_images = stripped.startswith("images:")
                    in_versions = stripped.startswith("versions:")
                else:
                    in_images = False
                    in_versions = False
                in_service = False

        if in_images and indent == 2 and stripped.startswith(f"{service_key}:"):
            in_service = True
            out.append(line)
            continue
        if in_images and indent == 2 and stripped.endswith(":") and not stripped.startswith(f"{service_key}:"):
            in_service = False

        if in_images and in_service and indent >= 4 and stripped.startswith("tag:"):
            out.append(f"{' ' * indent}tag: {tag}\n")
            updated_image = True
            continue

        if in_versions and indent == 2 and stripped.startswith(f"{version_key}:"):
            out.append(f"{' ' * indent}{version_key}: \"{tag}\"\n")
            updated_version = True
            continue

        out.append(line)

    if not updated_image:
        raise SystemExit(f"failed to update images.{service_key}.tag")
    if not updated_version:
        raise SystemExit(f"failed to update versions.{version_key}")

    path.write_text("".join(out))
    print(f"Updated images.{service_key}.tag and versions.{version_key} -> {tag}")


if __name__ == "__main__":
    if len(sys.argv) != 4:
        raise SystemExit("usage: bump_values.py <values.yaml> <service_key> <image_tag>")
    bump(Path(sys.argv[1]), sys.argv[2], sys.argv[3])

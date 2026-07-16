#!/usr/bin/env python3
"""Ensure charts/*/values.yaml point at ECR (accountId + region + short repo names).

Usage:
  ensure_ecr_registry.py <values.yaml> [--chart api-pulse|odin]

Env:
  AWS_ACCOUNT_ID  (required)
  AWS_REGION      (default us-west-2)
"""
from __future__ import annotations

import os
import re
import sys
from pathlib import Path


def ensure(path: Path, chart: str) -> bool:
    account = os.environ.get("AWS_ACCOUNT_ID", "").strip()
    region = os.environ.get("AWS_REGION", "us-west-2").strip() or "us-west-2"
    if not account or not account.isdigit() or len(account) != 12:
        raise SystemExit("AWS_ACCOUNT_ID must be a 12-digit account id")

    text = path.read_text()
    original = text
    registry = f"{account}.dkr.ecr.{region}.amazonaws.com"

    # imageRegistry line
    if re.search(r"^imageRegistry:\s*.*$", text, re.M):
        text = re.sub(r"^imageRegistry:\s*.*$", f"imageRegistry: {registry}", text, count=1, flags=re.M)
    else:
        text = f"imageRegistry: {registry}\n" + text

    # ecr block (insert or replace)
    ecr_block = f"ecr:\n  accountId: \"{account}\"\n  region: {region}\n"
    if re.search(r"^ecr:\s*$", text, re.M):
        text = re.sub(
            r"^ecr:\n(?:  .*\n)*",
            ecr_block,
            text,
            count=1,
            flags=re.M,
        )
    else:
        text = re.sub(
            r"^(imageRegistry:.*\n)",
            r"\1" + ecr_block,
            text,
            count=1,
            flags=re.M,
        )

    # Short repository names (strip Docker Hub namespaces)
    if chart == "api-pulse":
        replacements = {
            r"(repository:\s*)rajashekhar2390/api-pulse-web\b": r"\1api-pulse-web",
            r"(repository:\s*)rajashekhar2390/api-pulse-auth-service\b": r"\1api-pulse-auth-service",
            r"(repository:\s*)rajashekhar2390/api-pulse-analytics-service\b": r"\1api-pulse-analytics-service",
        }
    else:
        replacements = {
            r"(repository:\s*)rajashekhar2390/odin-api\b": r"\1odin-api",
            r"(repository:\s*)rajashekhar2390/odin-ui\b": r"\1odin-ui",
        }
    for pattern, repl in replacements.items():
        text = re.sub(pattern, repl, text)

    # Prefer ECR pull secret name
    text = re.sub(
        r"(imagePullSecrets:\n(?:  .*\n)*?  name:\s*)\S+",
        r"\1ecr-pull",
        text,
        count=1,
    )
    text = re.sub(
        r"(imagePullSecrets:\n  enabled:\s*)false",
        r"\1true",
        text,
        count=1,
    )

    if text != original:
        path.write_text(text)
        print(f"Updated {path} → registry {registry}")
        return True
    print(f"No change for {path} (already on {registry})")
    return False


if __name__ == "__main__":
    if len(sys.argv) < 2:
        raise SystemExit("usage: ensure_ecr_registry.py <values.yaml> [--chart api-pulse|odin]")
    values = Path(sys.argv[1])
    chart = "api-pulse"
    if "--chart" in sys.argv:
        chart = sys.argv[sys.argv.index("--chart") + 1]
    elif "odin" in values.as_posix():
        chart = "odin"
    ensure(values, chart)

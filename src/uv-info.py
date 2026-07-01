#!/usr/bin/env python3
"""Tiny uv-runner command for the Base demo."""

from __future__ import annotations

import sys


def main() -> int:
    print("base-demo uv runner")
    print(f"python={sys.version_info.major}.{sys.version_info.minor}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

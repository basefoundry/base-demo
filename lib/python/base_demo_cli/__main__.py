"""Entry point for the base-demo Python CLI."""

from __future__ import annotations

import os


def _print_env(name: str) -> None:
    print(f"{name}={os.environ.get(name, 'unset')}")


def main() -> int:
    print("base-demo python cli")
    _print_env("BASE_PROJECT")
    _print_env("BASE_PROJECT_ROOT")
    _print_env("BASE_PROJECT_MANIFEST")
    _print_env("BASE_PROJECT_VENV_DIR")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

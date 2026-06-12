"""Entry point for the base-demo Python CLI."""

from __future__ import annotations

import os

import base_cli

app = base_cli.App(name="base_demo_cli")


@app.command()
def run(ctx: base_cli.Context) -> None:
    """Show the Base project environment for base-demo."""
    ctx.log.debug("base_demo_cli starting")
    print("base-demo python cli")
    for var in ("BASE_PROJECT", "BASE_PROJECT_ROOT", "BASE_PROJECT_MANIFEST", "BASE_PROJECT_VENV_DIR"):
        print(f"{var}={os.environ.get(var, 'unset')}")


if __name__ == "__main__":
    app()

"""Entry point for the base-demo Python CLI."""

from __future__ import annotations

import os

import base_cli

app = base_cli.App(name="base_demo_cli")


def _project_name(ctx: base_cli.Context) -> str:
    if os.environ.get("BASE_PROJECT"):
        return os.environ["BASE_PROJECT"]
    if ctx.project_root is not None:
        return ctx.project_root.name
    return "unset"


@app.subcommand()
def info(ctx: base_cli.Context) -> int:
    """Show Base context values for base-demo."""
    ctx.log.debug("base_demo_cli info command")
    print("base-demo python cli")
    print(f"project_name={_project_name(ctx)}")
    print(f"project_root={ctx.project_root}")
    print(f"workspace_root={ctx.workspace_root}")
    return base_cli.ExitCode.SUCCESS


@app.subcommand()
def env(ctx: base_cli.Context) -> int:
    """Show BASE_* environment variables visible to the project command."""
    ctx.log.debug("base_demo_cli env command")
    for key in sorted(name for name in os.environ if name.startswith("BASE_")):
        print(f"{key}={os.environ[key]}")
    return base_cli.ExitCode.SUCCESS


if __name__ == "__main__":
    app()

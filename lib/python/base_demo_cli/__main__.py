"""Entry point for the base-demo Python CLI."""

from __future__ import annotations

import os
import re

import base_cli

app = base_cli.App(name="base_demo_cli")

_PUBLIC_BASE_ENVIRONMENT_NAMES = frozenset(
    {
        "BASE_CLI_SOURCE",
        "BASE_DEMO_ACTIVATED",
        "BASE_DEMO_ENV",
        "BASE_DEMO_PROJECT_KIND",
        "BASE_HOST",
        "BASE_HOST_ENV",
        "BASE_OS",
        "BASE_PLATFORM",
        "BASE_PROJECT",
        "BASE_PROJECT_MANIFEST",
        "BASE_PROJECT_ROOT",
        "BASE_PROJECT_VENV_DIR",
    }
)
_SENSITIVE_BASE_ENVIRONMENT_NAME = re.compile(
    r"(?:^|_)(?:TOKEN|KEY|APIKEY|PASSWORD|SECRET|CREDENTIALS?|AUTHORIZATION)(?:_|$)",
    re.IGNORECASE,
)
_REDACTED = "[REDACTED]"


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
    """Show the public Base environment visible to the project command."""
    ctx.log.debug("base_demo_cli env command")
    for key in sorted(name for name in os.environ if name.startswith("BASE_")):
        if _SENSITIVE_BASE_ENVIRONMENT_NAME.search(key):
            print(f"{key}={_REDACTED}")
        elif key in _PUBLIC_BASE_ENVIRONMENT_NAMES:
            print(f"{key}={os.environ[key]}")
    return base_cli.ExitCode.SUCCESS


if __name__ == "__main__":
    app()

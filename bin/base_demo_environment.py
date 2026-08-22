"""Shared loading and validation for base-demo environment configuration."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any


REQUIRED_FIELDS = (
    "name",
    "mode",
    "operational",
    "base_url",
    "logging",
    "services",
    "infrastructure",
)


def environment_names(root: Path) -> list[str]:
    directory = root / "environments"
    return sorted(path.stem for path in directory.glob("*.json") if path.is_file())


def load_environment(root: Path, name: str) -> dict[str, Any]:
    path = root / "environments" / f"{name}.json"
    try:
        with path.open(encoding="utf-8") as handle:
            payload = json.load(handle)
    except FileNotFoundError:
        raise ValueError(f"environment not found: {name}") from None
    except json.JSONDecodeError as exc:
        raise ValueError(f"environment {name} is not valid JSON: {exc}") from None
    if not isinstance(payload, dict):
        raise ValueError(f"environment {name} must be a JSON object")
    return payload


def validate_environment(name: str, payload: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    for field in REQUIRED_FIELDS:
        if field not in payload:
            errors.append(f"missing field: {field}")
    if payload.get("name") != name:
        errors.append(f"name must be {name}")
    if payload.get("mode") not in {"operational", "modeled"}:
        errors.append("mode must be operational or modeled")
    if not isinstance(payload.get("operational"), bool):
        errors.append("operational must be a boolean")
    if payload.get("mode") == "modeled" and payload.get("operational") is True:
        errors.append("modeled environments must not be operational")
    if not isinstance(payload.get("logging"), dict):
        errors.append("logging must be an object")
    if not isinstance(payload.get("services"), dict):
        errors.append("services must be an object")
    if not isinstance(payload.get("infrastructure"), dict):
        errors.append("infrastructure must be an object")
    return errors


def load_validated_environment(root: Path, name: str) -> dict[str, Any]:
    payload = load_environment(root, name)
    errors = validate_environment(name, payload)
    if errors:
        raise ValueError(f"environment {name} is invalid: {'; '.join(errors)}")
    return payload

"""Shared loading and validation for base-demo environment configuration."""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any
from urllib.parse import urlsplit


REQUIRED_FIELDS = (
    "name",
    "mode",
    "operational",
    "base_url",
    "logging",
    "services",
    "infrastructure",
)
LOG_LEVELS = {"debug", "info", "warn", "error"}
LOG_FORMATS = {"text", "json"}
SERVICE_OVERRIDE_FIELDS = {"required"}
INFRASTRUCTURE_OVERRIDE_FIELDS = {"enabled", "port"}
SERVICE_NAME_PATTERN = re.compile(r"[a-z0-9](?:[a-z0-9-]*[a-z0-9])?")
SERVICE_NAME_REQUIREMENT = (
    "must be a lowercase slug containing only letters, digits, and internal hyphens"
)


def validate_service_name(value: Any, location: str) -> str:
    if not isinstance(value, str) or SERVICE_NAME_PATTERN.fullmatch(value) is None:
        raise ValueError(f"{location} {SERVICE_NAME_REQUIREMENT}")
    return value


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


def compose_service_names(root: Path) -> set[str]:
    path = root / "infra" / "compose.yaml"
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except FileNotFoundError:
        raise ValueError(f"Compose configuration not found: {path}") from None

    names: set[str] = set()
    in_services = False
    for line in lines:
        if line == "services:":
            in_services = True
            continue
        if not in_services:
            continue
        if line and not line.startswith((" ", "\t", "#")):
            break
        match = re.fullmatch(r"  ([a-zA-Z0-9][a-zA-Z0-9_-]*):\s*", line)
        if match:
            names.add(match.group(1))
    if not names:
        raise ValueError(f"Compose configuration has no services: {path}")
    return names


def catalog_contract(root: Path) -> tuple[set[str], set[str]]:
    path = root / "services" / "catalog.json"
    try:
        with path.open(encoding="utf-8") as handle:
            payload = json.load(handle)
    except FileNotFoundError:
        raise ValueError(f"service catalog not found: {path}") from None
    except json.JSONDecodeError as exc:
        raise ValueError(f"service catalog is not valid JSON: {exc}") from None

    entries = payload.get("services") if isinstance(payload, dict) else None
    if not isinstance(entries, list):
        raise ValueError("service catalog must contain a services array")

    service_names: set[str] = set()
    infrastructure_compose_names: dict[str, str] = {}
    for index, entry in enumerate(entries):
        if not isinstance(entry, dict):
            raise ValueError(f"service catalog services[{index}] must be an object")
        entry_name = validate_service_name(
            entry.get("name"), f"service catalog services[{index}].name"
        )
        if entry_name in service_names or entry_name in infrastructure_compose_names:
            raise ValueError(f"service catalog contains duplicate name: {entry_name}")
        compose_name = entry.get("compose_service")
        if entry.get("kind") in {"database", "cache"}:
            if not isinstance(compose_name, str) or not compose_name:
                raise ValueError(
                    f"service catalog infrastructure {entry_name} must declare compose_service"
                )
            if compose_name in infrastructure_compose_names.values():
                raise ValueError(
                    f"service catalog contains duplicate infrastructure Compose service: {compose_name}"
                )
            infrastructure_compose_names[entry_name] = compose_name
            continue
        service_names.add(entry_name)

    compose_names = compose_service_names(root) if infrastructure_compose_names else set()
    infrastructure_names = {
        name
        for name, compose_name in infrastructure_compose_names.items()
        if compose_name in compose_names
    }
    return service_names, infrastructure_names


def valid_http_url(value: Any) -> bool:
    if not isinstance(value, str) or not value or any(character.isspace() for character in value):
        return False
    try:
        parsed = urlsplit(value)
        _ = parsed.port
    except ValueError:
        return False
    return (
        parsed.scheme in {"http", "https"}
        and parsed.hostname is not None
        and parsed.username is None
        and parsed.password is None
    )


def validate_environment(
    name: str, payload: dict[str, Any], *, root: Path | None = None
) -> list[str]:
    errors: list[str] = []
    for field in REQUIRED_FIELDS:
        if field not in payload:
            errors.append(f"missing field: {field}")
    if payload.get("name") != name:
        errors.append(f"name must be {name}")
    if not re.fullmatch(r"[a-z][a-z0-9-]*", name):
        errors.append("environment filename must use lowercase letters, digits, and hyphens")
    if payload.get("mode") not in {"operational", "modeled"}:
        errors.append("mode must be operational or modeled")
    if not isinstance(payload.get("operational"), bool):
        errors.append("operational must be a boolean")
    if payload.get("mode") == "modeled" and payload.get("operational") is True:
        errors.append("modeled environments must not be operational")
    if payload.get("mode") == "operational" and payload.get("operational") is False:
        errors.append("operational environments must set operational to true")
    if not valid_http_url(payload.get("base_url")):
        errors.append("base_url must be an http or https URL without credentials")

    unknown_fields = sorted(set(payload) - set(REQUIRED_FIELDS))
    for field in unknown_fields:
        errors.append(f"unsupported field: {field}")

    logging = payload.get("logging")
    if not isinstance(logging, dict):
        errors.append("logging must be an object")
    else:
        for field in sorted(set(logging) - {"level", "format"}):
            errors.append(f"logging.{field} is not supported")
        if logging.get("level") not in LOG_LEVELS:
            errors.append("logging.level must be one of: debug, error, info, warn")
        if logging.get("format") not in LOG_FORMATS:
            errors.append("logging.format must be one of: json, text")

    services = payload.get("services")
    if not isinstance(services, dict):
        errors.append("services must be an object")
        services = {}
    else:
        for service_name, override in sorted(services.items()):
            path = f"services.{service_name}"
            if not isinstance(override, dict):
                errors.append(f"{path} must be an object")
                continue
            for field in sorted(set(override) - SERVICE_OVERRIDE_FIELDS):
                errors.append(f"{path}.{field} is not supported")
            if not isinstance(override.get("required"), bool):
                errors.append(f"{path}.required must be a boolean")

    infrastructure = payload.get("infrastructure")
    if not isinstance(infrastructure, dict):
        errors.append("infrastructure must be an object")
        infrastructure = {}
    else:
        for infrastructure_name, override in sorted(infrastructure.items()):
            path = f"infrastructure.{infrastructure_name}"
            if not isinstance(override, dict):
                errors.append(f"{path} must be an object")
                continue
            for field in sorted(set(override) - INFRASTRUCTURE_OVERRIDE_FIELDS):
                errors.append(f"{path}.{field} is not supported")
            if not isinstance(override.get("enabled"), bool):
                errors.append(f"{path}.enabled must be a boolean")
            port = override.get("port")
            if isinstance(port, bool) or not isinstance(port, int) or not 1 <= port <= 65535:
                errors.append(f"{path}.port must be an integer from 1 to 65535")

    if root is not None and isinstance(services, dict) and isinstance(infrastructure, dict):
        try:
            catalog_services, catalog_infrastructure = catalog_contract(root)
        except ValueError as exc:
            errors.append(f"reference contract is invalid: {exc}")
        else:
            for service_name in sorted(set(services) - catalog_services):
                errors.append(
                    f"services.{service_name} must reference a non-infrastructure catalog service"
                )
            for infrastructure_name in sorted(set(infrastructure) - catalog_infrastructure):
                errors.append(
                    f"infrastructure.{infrastructure_name} must reference a catalog "
                    "database/cache with a Compose service"
                )
    return errors


def load_validated_environment(root: Path, name: str) -> dict[str, Any]:
    payload = load_environment(root, name)
    errors = validate_environment(name, payload, root=root)
    if errors:
        raise ValueError(f"environment {name} is invalid: {'; '.join(errors)}")
    return payload

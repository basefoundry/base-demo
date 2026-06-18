#!/usr/bin/env python3
"""Tiny standard-library HTTP API for the representative Python service."""

from __future__ import annotations

import json
import os
from wsgiref.simple_server import make_server


SERVICE_NAME = "python-api"
RUNTIME_NAME = "python"
DEFAULT_PORT = 8020


def json_response(payload: dict[str, object], status: str = "200 OK") -> tuple[str, list[tuple[str, str]], bytes]:
    body = json.dumps(payload, separators=(",", ":")).encode("utf-8")
    headers = [
        ("Content-Type", "application/json"),
        ("Content-Length", str(len(body))),
    ]
    return status, headers, body


def application(environ: dict[str, object], start_response) -> list[bytes]:
    path = str(environ.get("PATH_INFO", "/"))
    if path == "/healthz":
        status, headers, body = json_response({"service": SERVICE_NAME, "status": "ok"})
    elif path == "/hello":
        status, headers, body = json_response({"service": SERVICE_NAME, "message": "hello from python-api"})
    elif path == "/info":
        status, headers, body = json_response(
            {
                "service": SERVICE_NAME,
                "runtime": RUNTIME_NAME,
                "port": DEFAULT_PORT,
            }
        )
    else:
        status, headers, body = json_response({"error": "not found"}, "404 Not Found")
    start_response(status, headers)
    return [body]


def port() -> int:
    return int(os.environ.get("PORT", str(DEFAULT_PORT)))


def main() -> int:
    listen_port = port()
    with make_server("127.0.0.1", listen_port, application) as server:
        print(f"{SERVICE_NAME} listening on http://127.0.0.1:{listen_port}", flush=True)
        server.serve_forever()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

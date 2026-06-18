"""Tests for the representative Python API service."""

from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path
from wsgiref.util import setup_testing_defaults


ROOT = Path(__file__).resolve().parents[1]
SERVICE_DIR = ROOT / "services" / "python-api"
sys.path.insert(0, str(SERVICE_DIR))

import server  # noqa: E402


def call_app(path: str) -> tuple[str, dict[str, str], dict[str, object]]:
    environ: dict[str, object] = {}
    setup_testing_defaults(environ)
    environ["PATH_INFO"] = path

    captured: dict[str, object] = {}

    def start_response(status: str, headers: list[tuple[str, str]]) -> None:
        captured["status"] = status
        captured["headers"] = dict(headers)

    body = b"".join(server.application(environ, start_response)).decode("utf-8")
    return str(captured["status"]), captured["headers"], json.loads(body)


class PythonApiTests(unittest.TestCase):
    def test_health_endpoint_reports_ok(self) -> None:
        status, headers, payload = call_app("/healthz")

        self.assertEqual(status, "200 OK")
        self.assertEqual(headers["Content-Type"], "application/json")
        self.assertEqual(payload["service"], "python-api")
        self.assertEqual(payload["status"], "ok")

    def test_hello_endpoint_identifies_service(self) -> None:
        status, _headers, payload = call_app("/hello")

        self.assertEqual(status, "200 OK")
        self.assertEqual(payload["message"], "hello from python-api")

    def test_info_endpoint_reports_runtime_and_port(self) -> None:
        status, _headers, payload = call_app("/info")

        self.assertEqual(status, "200 OK")
        self.assertEqual(payload["service"], "python-api")
        self.assertEqual(payload["runtime"], "python")
        self.assertEqual(payload["port"], 8020)


if __name__ == "__main__":
    unittest.main()

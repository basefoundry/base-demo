"""Exercise representative API services through their real HTTP listeners."""

from __future__ import annotations

import json
import os
import signal
import socket
import subprocess
import tempfile
import time
import urllib.error
import urllib.request
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
READINESS_TIMEOUT_SECONDS = 15.0
REQUEST_TIMEOUT_SECONDS = 3.0
POLL_INTERVAL_SECONDS = 0.1
HTTP_OPENER = urllib.request.build_opener(urllib.request.ProxyHandler({}))


@dataclass(frozen=True)
class Service:
    name: str
    runtime: str
    command: tuple[str, ...]


SERVICES = (
    Service(
        name="go-api",
        runtime="go",
        command=("{go_binary}",),
    ),
    Service(
        name="python-api",
        runtime="python",
        command=("python3", "services/python-api/server.py"),
    ),
    Service(
        name="java-gradle-api",
        runtime="java-gradle",
        command=("./services/java-gradle-api/run.sh",),
    ),
    Service(
        name="java-maven-api",
        runtime="java-maven",
        command=("./services/java-maven-api/run.sh",),
    ),
)


class SmokeFailure(RuntimeError):
    """Raised when a service fails to start or violates its HTTP contract."""


def free_loopback_port() -> int:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as listener:
        listener.bind(("127.0.0.1", 0))
        return int(listener.getsockname()[1])


def build_go_binary(path: Path) -> None:
    environment = os.environ.copy()
    environment["CGO_ENABLED"] = "0"
    try:
        completed = subprocess.run(
            ["go", "build", "-o", str(path), "."],
            cwd=ROOT / "services" / "go-api",
            env=environment,
            check=False,
            capture_output=True,
            text=True,
            timeout=READINESS_TIMEOUT_SECONDS,
        )
    except (OSError, subprocess.SubprocessError) as exc:
        raise SmokeFailure(f"Unable to build go-api for live smoke testing: {exc}") from exc
    if completed.returncode != 0:
        details = (completed.stdout + completed.stderr).strip()
        raise SmokeFailure(f"Unable to build go-api for live smoke testing: {details}")


def request(url: str) -> tuple[int, str, bytes]:
    request = urllib.request.Request(url, method="GET")
    try:
        with HTTP_OPENER.open(request, timeout=REQUEST_TIMEOUT_SECONDS) as response:
            status = response.status
            content_type = response.headers.get("Content-Type", "")
            body = response.read()
    except urllib.error.HTTPError as exc:
        status = exc.code
        content_type = exc.headers.get("Content-Type", "")
        body = exc.read()
    except (OSError, urllib.error.URLError) as exc:
        raise SmokeFailure(f"GET {url} failed: {exc}") from exc

    return status, content_type, body


def request_json(url: str) -> tuple[int, str, dict[str, object]]:
    status, content_type, body = request(url)

    try:
        payload = json.loads(body.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise SmokeFailure(f"GET {url} returned invalid JSON: {body!r}") from exc
    if not isinstance(payload, dict):
        raise SmokeFailure(f"GET {url} returned a non-object JSON payload: {payload!r}")
    return status, content_type, payload


def assert_response(
    service: Service,
    port: int,
    path: str,
    expected_status: int,
    expected_payload: dict[str, object],
) -> None:
    url = f"http://127.0.0.1:{port}{path}"
    status, content_type, payload = request_json(url)
    if status != expected_status:
        raise SmokeFailure(f"{service.name} {path}: status {status}, expected {expected_status}")
    if not content_type.startswith("application/json"):
        raise SmokeFailure(f"{service.name} {path}: Content-Type {content_type!r} is not JSON")
    if payload != expected_payload:
        raise SmokeFailure(f"{service.name} {path}: payload {payload!r}, expected {expected_payload!r}")


def assert_not_found(service: Service, port: int) -> None:
    url = f"http://127.0.0.1:{port}/missing"
    status, content_type, body = request(url)
    if status != 404:
        raise SmokeFailure(f"{service.name} /missing: status {status}, expected 404")
    if service.name == "go-api":
        if not content_type.startswith("text/plain") or body != b"404 page not found\n":
            raise SmokeFailure(
                f"{service.name} /missing: body/content type {body!r}/{content_type!r} "
                "does not match the net/http 404 contract"
            )
        return
    if not content_type.startswith("application/json"):
        raise SmokeFailure(f"{service.name} /missing: Content-Type {content_type!r} is not JSON")
    try:
        payload = json.loads(body.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise SmokeFailure(f"{service.name} /missing returned invalid JSON: {body!r}") from exc
    if payload != {"error": "not found"}:
        raise SmokeFailure(f"{service.name} /missing: payload {payload!r}, expected {{'error': 'not found'}}")


def stop_process(process: subprocess.Popen[str]) -> None:
    if process.poll() is not None:
        return
    try:
        if os.name == "posix":
            os.killpg(process.pid, signal.SIGTERM)
        else:
            process.terminate()
        process.wait(timeout=5)
    except (OSError, subprocess.TimeoutExpired):
        if process.poll() is None:
            if os.name == "posix":
                os.killpg(process.pid, signal.SIGKILL)
            else:
                process.kill()
            process.wait(timeout=5)


def run_service(service: Service, command: tuple[str, ...], log_path: Path) -> None:
    port = free_loopback_port()
    environment = os.environ.copy()
    environment["PORT"] = str(port)
    with log_path.open("w", encoding="utf-8") as log_handle:
        try:
            process = subprocess.Popen(
                list(command),
                cwd=ROOT,
                env=environment,
                stdout=log_handle,
                stderr=subprocess.STDOUT,
                start_new_session=True,
                text=True,
            )
        except OSError as exc:
            raise SmokeFailure(f"Unable to start {service.name}: {exc}") from exc

        try:
            deadline = time.monotonic() + READINESS_TIMEOUT_SECONDS
            health_url = f"http://127.0.0.1:{port}/healthz"
            while time.monotonic() < deadline:
                if process.poll() is not None:
                    raise SmokeFailure(f"{service.name} exited with status {process.returncode}")
                try:
                    status, _content_type, _payload = request_json(health_url)
                except SmokeFailure:
                    time.sleep(POLL_INTERVAL_SECONDS)
                    continue
                if status == 200:
                    break
            else:
                raise SmokeFailure(f"{service.name} did not become ready within {READINESS_TIMEOUT_SECONDS:g}s")

            assert_response(service, port, "/healthz", 200, {"service": service.name, "status": "ok"})
            assert_response(
                service,
                port,
                "/hello",
                200,
                {"service": service.name, "message": f"hello from {service.name}"},
            )
            assert_response(
                service,
                port,
                "/info",
                200,
                {"service": service.name, "runtime": service.runtime, "port": port},
            )
            assert_not_found(service, port)
        finally:
            stop_process(process)


def main() -> int:
    with tempfile.TemporaryDirectory(prefix="base-demo-live-api-") as temporary_directory:
        temporary_root = Path(temporary_directory)
        go_binary = temporary_root / "go-api"
        build_go_binary(go_binary)
        for service in SERVICES:
            command = tuple(go_binary.as_posix() if item == "{go_binary}" else item for item in service.command)
            log_path = temporary_root / f"{service.name}.log"
            try:
                run_service(service, command, log_path)
            except SmokeFailure as exc:
                log = log_path.read_text(encoding="utf-8", errors="replace")
                raise SmokeFailure(f"{exc}\n{service.name} log:\n{log}") from exc
            print(f"{service.name}: live HTTP contract passed")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except SmokeFailure as exc:
        raise SystemExit(f"live API smoke failed: {exc}") from exc

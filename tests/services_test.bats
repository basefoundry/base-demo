#!/usr/bin/env bats

setup() {
  TEST_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd -P)"
  TEST_TMPDIR="$(mktemp -d "${TMPDIR:-/tmp}/base-demo-services-test.XXXXXX")"
  UNRELATED_PID=""
}

teardown() {
  if [[ -n "$UNRELATED_PID" ]]; then
    kill "$UNRELATED_PID" 2>/dev/null || true
    wait "$UNRELATED_PID" 2>/dev/null || true
  fi
  rm -rf "$TEST_TMPDIR"
}

write_optional_file_catalog() {
  local catalog="$1"

  cat > "$catalog" <<EOF
{
  "services": [
    {
      "name": "optional-file",
      "kind": "service",
      "runtime": "test",
      "port": null,
      "health_url": null,
      "required": false,
      "lifecycle": {
        "type": "process",
        "command": [
          "python3",
          "-c",
          "import time; time.sleep(60)"
        ]
      },
      "check": {
        "type": "file",
        "path": "missing.optional"
      },
      "logs": "var/services/optional-file.log"
    }
  ]
}
EOF
}

write_short_process_catalog() {
  local catalog="$1"

  cat > "$catalog" <<EOF
{
  "services": [
    {
      "name": "private-log",
      "kind": "service",
      "runtime": "test",
      "port": null,
      "health_url": null,
      "required": false,
      "lifecycle": {
        "type": "process",
        "command": [
          "python3",
          "-c",
          "print('private log')"
        ]
      },
      "check": {
        "type": "none"
      },
      "logs": "var/services/private-log.log"
    }
  ]
}
EOF
}

write_stable_process_catalog() {
  local catalog="$1"

  cat > "$catalog" <<EOF
{
  "services": [
    {
      "name": "stable-log",
      "kind": "service",
      "runtime": "test",
      "port": null,
      "health_url": null,
      "required": false,
      "lifecycle": {
        "type": "process",
        "command": ["python3", "-c", "import time; time.sleep(60)"]
      },
      "check": {"type": "none"},
      "logs": "var/services/stable-log.log"
    }
  ]
}
EOF
}

write_named_process_catalog() {
  local catalog="$1"
  local name="$2"
  local marker="$3"

  python3 - "$catalog" "$name" "$marker" <<'PY'
import json
import sys

catalog, name, marker = sys.argv[1:]
with open(catalog, "w", encoding="utf-8") as handle:
    json.dump(
        {
            "services": [
                {
                    "name": name,
                    "kind": "service",
                    "runtime": "test",
                    "required": False,
                    "lifecycle": {
                        "type": "process",
                        "command": [
                            "python3",
                            "-c",
                            f"import pathlib; pathlib.Path({marker!r}).touch()",
                        ],
                    },
                    "check": {"type": "none"},
                    "logs": None,
                }
            ]
        },
        handle,
    )
PY
}

write_readiness_timeout_catalog() {
  local catalog="$1"

  cat > "$catalog" <<EOF
{
  "services": [
    {
      "name": "slow-readiness",
      "kind": "service",
      "runtime": "test",
      "port": 1,
      "health_url": "http://127.0.0.1:1/healthz",
      "required": false,
      "lifecycle": {
        "type": "process",
        "command": ["python3", "-c", "import time; time.sleep(60)"]
      },
      "check": {"type": "http"},
      "logs": "var/services/slow-readiness.log"
    }
  ]
}
EOF
}

write_delayed_readiness_catalog() {
  local catalog="$1"
  local ready_file="$2"

  cat > "$catalog" <<EOF
{
  "services": [
    {
      "name": "delayed-readiness",
      "kind": "service",
      "runtime": "test",
      "port": null,
      "health_url": null,
      "required": false,
      "lifecycle": {
        "type": "process",
        "command": ["python3", "-c", "import pathlib,time; time.sleep(0.3); pathlib.Path('$ready_file').touch(); time.sleep(60)"]
      },
      "check": {"type": "file", "path": "$ready_file"},
      "logs": "var/services/delayed-readiness.log"
    }
  ]
}
EOF
}

file_mode() {
  if stat -f '%Lp' "$1" >/dev/null 2>&1; then
    stat -f '%Lp' "$1"
    return
  fi
  stat -c '%a' "$1"
}

write_optional_compose_catalog() {
  local catalog="$1"

  cat > "$catalog" <<EOF
{
  "services": [
    {
      "name": "optional-compose",
      "kind": "service",
      "runtime": "compose",
      "port": null,
      "health_url": null,
      "required": false,
      "compose_service": "optional-compose",
      "check": {
        "type": "compose",
        "service": "optional-compose"
      },
      "logs": "docker compose logs optional-compose"
    }
  ]
}
EOF
}

write_missing_http_catalog() {
  local catalog="$1"

  cat > "$catalog" <<EOF
{
  "services": [
    {
      "name": "missing-http",
      "kind": "service",
      "runtime": "test",
      "port": null,
      "health_url": null,
      "required": false,
      "check": {
        "type": "http"
      },
      "logs": null
    }
  ]
}
EOF
}

write_fake_docker_with_stopped_compose_service() {
  local bin_dir="$1"
  mkdir -p "$bin_dir"
  cat > "$bin_dir/docker" <<'EOF'
#!/usr/bin/env bash
if [[ "$*" == *"ps --services --status running"* ]]; then
  exit 0
fi
if [[ "$*" == *"ps --services --all"* ]]; then
  printf 'optional-compose\n'
  exit 0
fi
exit 0
EOF
  chmod +x "$bin_dir/docker"
}

write_transaction_fake_docker() {
  local bin_dir="$1"
  mkdir -p "$bin_dir"
  cat > "$bin_dir/docker" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$FAKE_DOCKER_LOG"
if [[ "$*" == *"ps --services --status running"* ]]; then
  exit 0
fi
if [[ "$*" == *"up -d"* ]]; then
  exit "${FAKE_DOCKER_UP_EXIT:-0}"
fi
if [[ "$*" == *"stop"* ]]; then
  exit "${FAKE_DOCKER_STOP_EXIT:-0}"
fi
exit 0
EOF
  chmod +x "$bin_dir/docker"
}

write_transaction_catalog() {
  local catalog="$1"
  local scenario="$2"
  local first_marker="$3"
  local later_marker="$4"

  python3 - "$catalog" "$scenario" "$first_marker" "$later_marker" <<'PY'
import json
import sys

catalog, scenario, first_marker, later_marker = sys.argv[1:]
services = [
    {
        "name": "transaction-db",
        "kind": "database",
        "runtime": "compose",
        "required": False,
        "compose_service": "transaction-db",
        "check": {"type": "compose", "service": "transaction-db"},
        "logs": None,
    }
]

if scenario == "invalid-plan":
    services.append(
        {
            "name": "invalid-process",
            "kind": "service",
            "runtime": "test",
            "required": False,
            "lifecycle": {"type": "process", "command": "not-an-array"},
            "check": {"type": "none"},
            "logs": None,
        }
    )
elif scenario == "compose-failure":
    services.append(
        {
            "name": "later-process",
            "kind": "service",
            "runtime": "test",
            "required": False,
            "lifecycle": {
                "type": "process",
                "command": [
                    "python3",
                    "-c",
                    f"import pathlib,time; pathlib.Path({later_marker!r}).touch(); time.sleep(60)",
                ],
            },
            "check": {"type": "none"},
            "logs": None,
        }
    )
elif scenario == "process-failure":
    services.extend(
        [
            {
                "name": "first-process",
                "kind": "service",
                "runtime": "test",
                "required": False,
                "lifecycle": {
                    "type": "process",
                    "command": [
                        "python3",
                        "-c",
                        f"import pathlib,time; pathlib.Path({first_marker!r}).touch(); time.sleep(60)",
                    ],
                },
                "check": {"type": "none"},
                "logs": None,
            },
            {
                "name": "failing-process",
                "kind": "service",
                "runtime": "test",
                "required": False,
                "lifecycle": {
                    "type": "process",
                    "command": ["python3", "-c", "raise SystemExit(9)"],
                },
                "check": {"type": "none"},
                "logs": None,
            },
            {
                "name": "later-process",
                "kind": "service",
                "runtime": "test",
                "required": False,
                "lifecycle": {
                    "type": "process",
                    "command": [
                        "python3",
                        "-c",
                        f"import pathlib,time; pathlib.Path({later_marker!r}).touch(); time.sleep(60)",
                    ],
                },
                "check": {"type": "none"},
                "logs": None,
            },
        ]
    )
else:
    raise SystemExit(f"unknown scenario: {scenario}")

with open(catalog, "w", encoding="utf-8") as handle:
    json.dump({"services": services}, handle)
PY
}

@test "services command is declared and executable" {
  grep -Fq "services: ./bin/base-demo-services" "$TEST_ROOT/base_manifest.yaml"
  [ -x "$TEST_ROOT/bin/base-demo-services" ]
  [ -f "$TEST_ROOT/services/catalog.json" ]
}

@test "services rejects malformed catalog containers without a traceback" {
  local catalog="$TEST_TMPDIR/catalog.json"
  local case_value
  local payload
  local expected
  local cases=(
    '[]|service catalog root must be an object'
    '{}|service catalog.services must be an array'
    '{"services": {}}|service catalog.services must be an array'
    '{"services": [null]}|service catalog.services[0] must be an object'
    '{"services": [7]}|service catalog.services[0] must be an object'
  )

  for case_value in "${cases[@]}"; do
    payload="${case_value%%|*}"
    expected="${case_value#*|}"
    printf '%s\n' "$payload" > "$catalog"

    run "$TEST_ROOT/bin/base-demo-services" --catalog "$catalog" status

    [ "$status" -eq 2 ]
    [[ "$output" == *"ERROR: $expected"* ]]
    [[ "$output" != *"Traceback"* ]]
  done
}

@test "services rejects wrong-typed catalog fields with field paths" {
  local catalog="$TEST_TMPDIR/catalog.json"
  local case_value
  local payload
  local expected
  local cases=(
    '{"version": "one", "services": []}|service catalog.version must be a positive integer'
    '{"services": [{"name": "bad", "kind": []}]}|service catalog.services[0].kind must be a non-empty string'
    '{"services": [{"name": "bad", "runtime": false}]}|service catalog.services[0].runtime must be a non-empty string'
    '{"services": [{"name": "bad", "port": true}]}|service catalog.services[0].port must be null or an integer from 1 to 65535'
    '{"services": [{"name": "bad", "health_url": []}]}|service catalog.services[0].health_url must be null or an http or https URL without credentials'
    '{"services": [{"name": "bad", "required": "yes"}]}|service catalog.services[0].required must be a boolean'
    '{"services": [{"name": "bad", "logs": {}}]}|service catalog.services[0].logs must be a non-empty string'
    '{"services": [{"name": "bad", "compose_service": 7}]}|service catalog.services[0].compose_service must be a non-empty string'
    '{"services": [{"name": "bad", "check": []}]}|service catalog.services[0].check must be an object'
    '{"services": [{"name": "bad", "check": {"type": 7}}]}|service catalog.services[0].check.type must be a non-empty string'
    '{"services": [{"name": "bad", "check": {"type": "command", "command": "echo"}}]}|service catalog.services[0].check.command must be a non-empty string array'
    '{"services": [{"name": "bad", "lifecycle": []}]}|service catalog.services[0].lifecycle must be an object'
    '{"services": [{"name": "bad", "lifecycle": {"type": "compose", "command": ["true"]}}]}|service catalog.services[0].lifecycle.type must be process'
    '{"services": [{"name": "bad", "lifecycle": {"type": "process", "command": "true"}}]}|service catalog.services[0].lifecycle.command must be a non-empty string array'
    '{"services": [{"name": "bad", "lifecycle": {"type": "process", "command": ["true"], "readiness_timeout_seconds": "fast"}}]}|service catalog.services[0].lifecycle.readiness_timeout_seconds must be a positive finite number'
  )

  for case_value in "${cases[@]}"; do
    payload="${case_value%%|*}"
    expected="${case_value#*|}"
    printf '%s\n' "$payload" > "$catalog"

    run "$TEST_ROOT/bin/base-demo-services" --catalog "$catalog" status

    [ "$status" -eq 2 ]
    [[ "$output" == *"ERROR: $expected"* ]]
    [[ "$output" != *"Traceback"* ]]
  done
}

@test "services status shows catalog entries" {
  run "$TEST_ROOT/bin/base-demo-services" status

  [ "$status" -eq 0 ]
  [[ "$output" == *"NAME"* ]]
  [[ "$output" == *"project-baseline"* ]]
  [[ "$output" == *"project"* ]]
  [[ "$output" == *"base"* ]]
  [[ "$output" == *"healthy"* ]]
}

@test "services check passes for healthy required entries" {
  run env BASE_DEMO_SERVICES_STATE_DIR="$TEST_TMPDIR/state" "$TEST_ROOT/bin/base-demo-services" check

  [ "$status" -eq 0 ]
  [[ "$output" == *"project-baseline ok"* ]]
}

@test "services check fails for unhealthy required entries" {
  local catalog="$TEST_TMPDIR/catalog.json"

  cat > "$catalog" <<EOF
{
  "services": [
    {
      "name": "missing-required",
      "kind": "service",
      "runtime": "test",
      "port": 9999,
      "health_url": null,
      "required": true,
      "check": {
        "type": "file",
        "path": "missing.file"
      },
      "logs": null
    }
  ]
}
EOF

  run "$TEST_ROOT/bin/base-demo-services" --catalog "$catalog" check

  [ "$status" -eq 1 ]
  [[ "$output" == *"missing-required fail"* ]]
  [[ "$output" == *"file:missing.file"* ]]
}

@test "services status keeps never-started optional services stopped" {
  local catalog="$TEST_TMPDIR/catalog.json"
  write_optional_file_catalog "$catalog"

  run env BASE_DEMO_SERVICES_STATE_DIR="$TEST_TMPDIR/state" "$TEST_ROOT/bin/base-demo-services" --catalog "$catalog" status

  [ "$status" -eq 0 ]
  [[ "$output" == *"optional-file"*"stopped"* ]]
  [[ "$output" != *"optional-file"*"error"* ]]
}

@test "services status treats dead stale process state as stopped" {
  local catalog="$TEST_TMPDIR/catalog.json"
  local state_dir="$TEST_TMPDIR/state"
  write_optional_file_catalog "$catalog"
  mkdir -p "$state_dir"
  cat > "$state_dir/optional-file.json" <<EOF
{
  "pid": 999999,
  "started_at": "2026-06-20T12:00:00+00:00",
  "command": ["python3", "-c", "import time; time.sleep(60)"],
  "log": "$state_dir/optional-file.log"
}
EOF

  run env BASE_DEMO_SERVICES_STATE_DIR="$state_dir" "$TEST_ROOT/bin/base-demo-services" --catalog "$catalog" status

  [ "$status" -eq 0 ]
  [[ "$output" == *"optional-file"*"stopped"* ]]
  [[ "$output" != *"2026-06-20T12:00:00+00:00"* ]]
}

@test "services check treats dead stale optional process state as stopped" {
  local catalog="$TEST_TMPDIR/catalog.json"
  local state_dir="$TEST_TMPDIR/state"
  write_optional_file_catalog "$catalog"
  mkdir -p "$state_dir"
  cat > "$state_dir/optional-file.json" <<EOF
{
  "pid": 999999,
  "started_at": "2026-06-20T12:00:00+00:00",
  "command": ["python3", "-c", "import time; time.sleep(60)"],
  "log": "$state_dir/optional-file.log"
}
EOF

  run env BASE_DEMO_SERVICES_STATE_DIR="$state_dir" "$TEST_ROOT/bin/base-demo-services" --catalog "$catalog" check

  [ "$status" -eq 0 ]
  [[ "$output" == *"optional-file skip optional process:stopped"* ]]
}

@test "services status marks optional compose services with existing state as error" {
  local catalog="$TEST_TMPDIR/catalog.json"
  local fake_bin="$TEST_TMPDIR/bin"
  write_optional_compose_catalog "$catalog"
  write_fake_docker_with_stopped_compose_service "$fake_bin"

  run env PATH="$fake_bin:$PATH" "$TEST_ROOT/bin/base-demo-services" --catalog "$catalog" status

  [ "$status" -eq 0 ]
  [[ "$output" == *"optional-compose"*"error"* ]]
}

@test "services status and check use the same missing http target detail" {
  local catalog="$TEST_TMPDIR/catalog.json"
  write_missing_http_catalog "$catalog"

  run env BASE_DEMO_SERVICES_STATE_DIR="$TEST_TMPDIR/state" "$TEST_ROOT/bin/base-demo-services" --catalog "$catalog" status

  [ "$status" -eq 0 ]
  [[ "$output" == *"missing-http"*"http:<missing health_url>"* ]]

  run env BASE_DEMO_SERVICES_STATE_DIR="$TEST_TMPDIR/state" "$TEST_ROOT/bin/base-demo-services" --catalog "$catalog" check

  [ "$status" -eq 0 ]
  [[ "$output" == *"missing-http skip optional http:<missing health_url>"* ]]
}

@test "services validates the complete lifecycle plan before Compose mutation" {
  local catalog="$TEST_TMPDIR/catalog.json"
  local fake_bin="$TEST_TMPDIR/bin"
  local docker_log="$TEST_TMPDIR/docker.log"
  write_transaction_catalog "$catalog" invalid-plan "$TEST_TMPDIR/first" "$TEST_TMPDIR/later"
  write_transaction_fake_docker "$fake_bin"

  run env PATH="$fake_bin:$PATH" FAKE_DOCKER_LOG="$docker_log" \
    BASE_DEMO_SERVICES_STATE_DIR="$TEST_TMPDIR/state" \
    "$TEST_ROOT/bin/base-demo-services" --catalog "$catalog" start

  [ "$status" -eq 2 ]
  [[ "$output" == *"service catalog.services[1].lifecycle.command must be a non-empty string array"* ]]
  [ ! -e "$docker_log" ]
}

@test "services stops after Compose start failure and rolls back the attempted resources" {
  local catalog="$TEST_TMPDIR/catalog.json"
  local fake_bin="$TEST_TMPDIR/bin"
  local docker_log="$TEST_TMPDIR/docker.log"
  local later_marker="$TEST_TMPDIR/later-ran"
  write_transaction_catalog "$catalog" compose-failure "$TEST_TMPDIR/first" "$later_marker"
  write_transaction_fake_docker "$fake_bin"

  run env PATH="$fake_bin:$PATH" FAKE_DOCKER_LOG="$docker_log" \
    FAKE_DOCKER_UP_EXIT=17 BASE_DEMO_SERVICES_STATE_DIR="$TEST_TMPDIR/state" \
    "$TEST_ROOT/bin/base-demo-services" --catalog "$catalog" start

  [ "$status" -eq 17 ]
  [[ "$output" == *"lifecycle start failed at compose (exit 17)"* ]]
  [[ "$output" == *"ROLLBACK compose:transaction-db ok"* ]]
  [ ! -e "$later_marker" ]
  [ "$(grep -c 'up -d transaction-db' "$docker_log")" -eq 1 ]
  [ "$(grep -c 'stop transaction-db' "$docker_log")" -eq 1 ]
}

@test "services restart never starts replacements after a stop failure" {
  local catalog="$TEST_TMPDIR/catalog.json"
  local fake_bin="$TEST_TMPDIR/bin"
  local docker_log="$TEST_TMPDIR/docker.log"
  local later_marker="$TEST_TMPDIR/later-ran"
  write_transaction_catalog "$catalog" compose-failure "$TEST_TMPDIR/first" "$later_marker"
  write_transaction_fake_docker "$fake_bin"

  run env PATH="$fake_bin:$PATH" FAKE_DOCKER_LOG="$docker_log" \
    FAKE_DOCKER_STOP_EXIT=31 BASE_DEMO_SERVICES_STATE_DIR="$TEST_TMPDIR/state" \
    "$TEST_ROOT/bin/base-demo-services" --catalog "$catalog" restart

  [ "$status" -eq 31 ]
  [[ "$output" == *"lifecycle stop failed at compose (exit 31)"* ]]
  [[ "$output" == *"lifecycle restart aborted after stop failure (exit 31)"* ]]
  [[ "$output" == *"no replacement services were started"* ]]
  [ ! -e "$later_marker" ]
  [ "$(grep -c 'stop transaction-db' "$docker_log")" -eq 1 ]
  ! grep -Fq 'up -d' "$docker_log"
}

@test "services rolls back prior work, skips later starts, and reports rollback failures" {
  local catalog="$TEST_TMPDIR/catalog.json"
  local fake_bin="$TEST_TMPDIR/bin"
  local docker_log="$TEST_TMPDIR/docker.log"
  local state_dir="$TEST_TMPDIR/state"
  local first_marker="$TEST_TMPDIR/first-ran"
  local later_marker="$TEST_TMPDIR/later-ran"
  write_transaction_catalog "$catalog" process-failure "$first_marker" "$later_marker"
  write_transaction_fake_docker "$fake_bin"

  run env PATH="$fake_bin:$PATH" FAKE_DOCKER_LOG="$docker_log" \
    FAKE_DOCKER_STOP_EXIT=23 BASE_DEMO_SERVICES_STATE_DIR="$state_dir" \
    "$TEST_ROOT/bin/base-demo-services" --catalog "$catalog" start

  [ "$status" -eq 1 ]
  [[ "$output" == *"lifecycle start failed at process:failing-process (exit 1)"* ]]
  [[ "$output" == *"ROLLBACK process:first-process ok"* ]]
  [[ "$output" == *"rollback compose:transaction-db exit 23"* ]]
  [[ "$output" == *"lifecycle start rollback failures: compose:transaction-db exit 23"* ]]
  [ -e "$first_marker" ]
  [ ! -e "$later_marker" ]
  [ ! -e "$state_dir/first-process.json" ]
  [ ! -e "$state_dir/later-process.json" ]
}

@test "services restart aborts before mutation when process ownership mismatches" {
  local catalog="$TEST_TMPDIR/catalog.json"
  local fake_bin="$TEST_TMPDIR/bin"
  local docker_log="$TEST_TMPDIR/docker.log"
  local state_dir="$TEST_TMPDIR/state"
  local state_path="$state_dir/stable-log.json"
  write_stable_process_catalog "$catalog"
  write_transaction_fake_docker "$fake_bin"
  python3 - "$catalog" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, encoding="utf-8") as handle:
    catalog = json.load(handle)
catalog["services"].insert(
    0,
    {
        "name": "transaction-db",
        "kind": "database",
        "runtime": "compose",
        "required": False,
        "compose_service": "transaction-db",
        "check": {"type": "compose", "service": "transaction-db"},
        "logs": None,
    },
)
with open(path, "w", encoding="utf-8") as handle:
    json.dump(catalog, handle)
PY
  mkdir -p "$state_dir"
  sleep 60 &
  UNRELATED_PID=$!
  cat > "$state_path" <<EOF
{
  "pid": $UNRELATED_PID,
  "process_group_id": $UNRELATED_PID,
  "process_start_time": "not-the-live-start-time",
  "started_at": "2026-08-24T00:00:00+00:00",
  "command": ["python3", "-c", "import time; time.sleep(60)"],
  "log": "$state_dir/stable-log.log"
}
EOF

  run env PATH="$fake_bin:$PATH" FAKE_DOCKER_LOG="$docker_log" \
    BASE_DEMO_SERVICES_STATE_DIR="$state_dir" \
    "$TEST_ROOT/bin/base-demo-services" --catalog "$catalog" restart

  [ "$status" -eq 1 ]
  [[ "$output" == *"lifecycle restart preflight failed at process:stable-log"* ]]
  [[ "$output" == *"No services were mutated and no replacement was started"* ]]
  grep -Fq "\"pid\": $UNRELATED_PID" "$state_path"
  [ ! -e "$docker_log" ]
  kill -0 "$UNRELATED_PID"

  run env PATH="$fake_bin:$PATH" FAKE_DOCKER_LOG="$docker_log" \
    BASE_DEMO_SERVICES_STATE_DIR="$state_dir" \
    "$TEST_ROOT/bin/base-demo-services" --catalog "$catalog" start

  [ "$status" -eq 1 ]
  [[ "$output" == *"lifecycle start preflight failed at process:stable-log"* ]]
  [ ! -e "$docker_log" ]
  grep -Fq "\"pid\": $UNRELATED_PID" "$state_path"
  kill "$UNRELATED_PID"
  wait "$UNRELATED_PID" 2>/dev/null || true
  UNRELATED_PID=""
}

@test "services start rejects immediate process exit and removes state" {
  local catalog="$TEST_TMPDIR/catalog.json"
  local state_dir="$TEST_TMPDIR/state"
  local log_path="$state_dir/private-log.log"
  write_short_process_catalog "$catalog"
  mkdir -p "$state_dir"
  touch "$log_path"
  chmod 0644 "$log_path"

  run env BASE_DEMO_SERVICES_START_TIMEOUT=0.5 BASE_DEMO_SERVICES_STATE_DIR="$state_dir" "$TEST_ROOT/bin/base-demo-services" --catalog "$catalog" start

  [ "$status" -eq 1 ]
  [[ "$output" == *"ERROR: private-log exited"* ]]
  [ -f "$log_path" ]
  [ "$(file_mode "$log_path")" = "600" ]
  [ ! -e "$state_dir/private-log.json" ]
}

@test "services start records identity and preserves private log permissions" {
  local catalog="$TEST_TMPDIR/catalog.json"
  local state_dir="$TEST_TMPDIR/state"
  local log_path="$state_dir/stable-log.log"
  local state_path="$state_dir/stable-log.json"
  write_stable_process_catalog "$catalog"
  mkdir -p "$state_dir"
  touch "$log_path"
  chmod 0644 "$log_path"

  run env BASE_DEMO_SERVICES_STATE_DIR="$state_dir" "$TEST_ROOT/bin/base-demo-services" --catalog "$catalog" start

  [ "$status" -eq 0 ]
  [[ "$output" == *"stable-log started pid="* ]]
  [ "$(file_mode "$log_path")" = "600" ]
  [ "$(file_mode "$state_path")" = "600" ]
  grep -Fq '"process_group_id":' "$state_path"
  grep -Fq '"process_start_time":' "$state_path"
  grep -Fq '"command":' "$state_path"
  [ -z "$(find "$state_dir" -name '.stable-log.json.*.tmp' -print -quit)" ]

  run env BASE_DEMO_SERVICES_STATE_DIR="$state_dir" "$TEST_ROOT/bin/base-demo-services" --catalog "$catalog" stop

  [ "$status" -eq 0 ]
  [[ "$output" == *"stable-log stopped"* ]]
  [ ! -e "$state_path" ]
}

@test "services rejects unsafe catalog names before lifecycle execution" {
  local catalog="$TEST_TMPDIR/catalog.json"
  local marker="$TEST_TMPDIR/lifecycle-ran"
  local name

  for name in '../escape' '/absolute' 'nested/name' 'nested\name' 'not_a_slug' $'control\nname'; do
    write_named_process_catalog "$catalog" "$name" "$marker"

    run env BASE_DEMO_SERVICES_STATE_DIR="$TEST_TMPDIR/state" "$TEST_ROOT/bin/base-demo-services" --catalog "$catalog" start

    [ "$status" -eq 2 ]
    [[ "$output" == *"services[0].name must be a lowercase slug"* ]]
    [ ! -e "$marker" ]
  done
}

@test "services rejects state and log symlinks before lifecycle execution" {
  local catalog="$TEST_TMPDIR/catalog.json"
  local state_dir="$TEST_TMPDIR/state"
  local outside_state="$TEST_TMPDIR/outside-state"
  local outside_log="$TEST_TMPDIR/outside-log"
  write_stable_process_catalog "$catalog"
  mkdir -p "$state_dir"
  printf 'outside-state\n' > "$outside_state"
  printf 'outside-log\n' > "$outside_log"
  ln -s "$outside_state" "$state_dir/stable-log.json"

  run env BASE_DEMO_SERVICES_STATE_DIR="$state_dir" "$TEST_ROOT/bin/base-demo-services" --catalog "$catalog" start

  [ "$status" -eq 2 ]
  [[ "$output" == *"service artifact path is not a safe state-directory child"* ]]
  [ "$(cat "$outside_state")" = "outside-state" ]
  [ -L "$state_dir/stable-log.json" ]

  rm "$state_dir/stable-log.json"
  ln -s "$outside_log" "$state_dir/stable-log.log"

  run env BASE_DEMO_SERVICES_STATE_DIR="$state_dir" "$TEST_ROOT/bin/base-demo-services" --catalog "$catalog" start

  [ "$status" -eq 2 ]
  [[ "$output" == *"service artifact path is not a safe state-directory child"* ]]
  [ "$(cat "$outside_log")" = "outside-log" ]
  [ -L "$state_dir/stable-log.log" ]
}

@test "services uses private state and log files in the default state directory" {
  local checkout="$TEST_TMPDIR/checkout"
  local catalog="$TEST_TMPDIR/catalog.json"
  local state_dir="$checkout/var/services"
  write_stable_process_catalog "$catalog"
  mkdir -p "$checkout/environments" "$checkout/services" "$checkout/infra"
  cp "$TEST_ROOT/environments/dev.json" "$checkout/environments/dev.json"
  cp "$TEST_ROOT/services/catalog.json" "$checkout/services/catalog.json"
  cp "$TEST_ROOT/infra/compose.yaml" "$checkout/infra/compose.yaml"

  run env BASE_PROJECT_ROOT="$checkout" "$TEST_ROOT/bin/base-demo-services" --catalog "$catalog" start

  [ "$status" -eq 0 ]
  [ "$(file_mode "$state_dir/stable-log.json")" = "600" ]
  [ "$(file_mode "$state_dir/stable-log.log")" = "600" ]

  run env BASE_PROJECT_ROOT="$checkout" "$TEST_ROOT/bin/base-demo-services" --catalog "$catalog" stop

  [ "$status" -eq 0 ]
}

@test "services start enforces readiness timeout and removes failed state" {
  local catalog="$TEST_TMPDIR/catalog.json"
  local state_dir="$TEST_TMPDIR/state"
  write_readiness_timeout_catalog "$catalog"

  run env BASE_DEMO_SERVICES_START_TIMEOUT=0.2 BASE_DEMO_SERVICES_STATE_DIR="$state_dir" "$TEST_ROOT/bin/base-demo-services" --catalog "$catalog" start

  [ "$status" -eq 1 ]
  [[ "$output" == *"slow-readiness failed readiness"* ]]
  [[ "$output" == *"http://127.0.0.1:1/healthz"* ]]
  [ ! -e "$state_dir/slow-readiness.json" ]
}

@test "services start waits for configured readiness before succeeding" {
  local catalog="$TEST_TMPDIR/catalog.json"
  local ready_file="$TEST_TMPDIR/ready"
  local state_dir="$TEST_TMPDIR/state"
  write_delayed_readiness_catalog "$catalog" "$ready_file"

  run env BASE_DEMO_SERVICES_START_TIMEOUT=2 BASE_DEMO_SERVICES_STATE_DIR="$state_dir" "$TEST_ROOT/bin/base-demo-services" --catalog "$catalog" start

  [ "$status" -eq 0 ]
  [[ "$output" == *"delayed-readiness started pid="* ]]
  [ -f "$ready_file" ]
  [ -f "$state_dir/delayed-readiness.json" ]

  run env BASE_DEMO_SERVICES_STATE_DIR="$state_dir" "$TEST_ROOT/bin/base-demo-services" --catalog "$catalog" stop

  [ "$status" -eq 0 ]
  [ ! -e "$state_dir/delayed-readiness.json" ]
}

@test "services stop refuses a live PID whose identity does not match state" {
  local catalog="$TEST_TMPDIR/catalog.json"
  local state_dir="$TEST_TMPDIR/state"
  local state_path="$state_dir/stable-log.json"
  write_stable_process_catalog "$catalog"
  mkdir -p "$state_dir"
  sleep 60 &
  UNRELATED_PID=$!
  cat > "$state_path" <<EOF
{
  "pid": $UNRELATED_PID,
  "process_group_id": $UNRELATED_PID,
  "process_start_time": "not-the-live-start-time",
  "started_at": "2026-08-22T00:00:00+00:00",
  "command": ["python3", "-c", "import time; time.sleep(60)"],
  "log": "$state_dir/stable-log.log"
}
EOF

  run env BASE_DEMO_SERVICES_STATE_DIR="$state_dir" "$TEST_ROOT/bin/base-demo-services" --catalog "$catalog" stop

  [ "$status" -eq 1 ]
  [[ "$output" == *"state does not match live pid=$UNRELATED_PID"* ]]
  [[ "$output" == *"refusing to signal it"* ]]
  kill -0 "$UNRELATED_PID"
  [ ! -e "$state_path" ]
  kill "$UNRELATED_PID"
  wait "$UNRELATED_PID" 2>/dev/null || true
  UNRELATED_PID=""
}

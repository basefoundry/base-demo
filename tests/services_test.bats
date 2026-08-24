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

@test "services command is declared and executable" {
  grep -Fq "services: ./bin/base-demo-services" "$TEST_ROOT/base_manifest.yaml"
  [ -x "$TEST_ROOT/bin/base-demo-services" ]
  [ -f "$TEST_ROOT/services/catalog.json" ]
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

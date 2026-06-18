#!/usr/bin/env bats

setup() {
  TEST_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd -P)"
  TEST_TMPDIR="$(mktemp -d "${TMPDIR:-/tmp}/base-demo-python-api-test.XXXXXX")"
  TEST_CATALOG="$TEST_TMPDIR/catalog.json"
  cat > "$TEST_CATALOG" <<EOF
{
  "services": [
    {
      "name": "python-api",
      "kind": "service",
      "runtime": "python",
      "port": 18020,
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
        "path": "base_manifest.yaml"
      },
      "logs": "var/services/python-api.log"
    }
  ]
}
EOF
}

teardown() {
  BASE_DEMO_SERVICES_STATE_DIR="$TEST_TMPDIR/state" "$TEST_ROOT/bin/base-demo-services" --catalog "$TEST_CATALOG" stop >/dev/null 2>&1 || true
  rm -rf "$TEST_TMPDIR"
}

@test "python api service files and catalog entry are present" {
  [ -f "$TEST_ROOT/services/python-api/server.py" ]
  [ -x "$TEST_ROOT/services/python-api/build.sh" ]
  [ -x "$TEST_ROOT/services/python-api/test.sh" ]
  grep -Fq '"name": "python-api"' "$TEST_ROOT/services/catalog.json"
  grep -Fq '"port": 8020' "$TEST_ROOT/services/catalog.json"
  grep -Fq "python-api:" "$TEST_ROOT/base_manifest.yaml"
}

@test "services status shows python api as python service" {
  run "$TEST_ROOT/bin/base-demo-services" status

  [ "$status" -eq 0 ]
  [[ "$output" == *"python-api"* ]]
  [[ "$output" == *"service"* ]]
  [[ "$output" == *"python"* ]]
  [[ "$output" == *"8020"* ]]
}

@test "services lifecycle dry-run includes python api process command" {
  run env BASE_DEMO_SERVICES_DRY_RUN=1 "$TEST_ROOT/bin/base-demo-services" start

  [ "$status" -eq 0 ]
  [[ "$output" == *"DRY-RUN docker compose"* ]]
  [[ "$output" == *"go-api"* ]]
  [[ "$output" == *"DRY-RUN start python-api"* ]]
  [[ "$output" == *"services/python-api/server.py"* ]]

  run env BASE_DEMO_SERVICES_DRY_RUN=1 "$TEST_ROOT/bin/base-demo-services" stop

  [ "$status" -eq 0 ]
  [[ "$output" == *"DRY-RUN docker compose"* ]]
  [[ "$output" == *"DRY-RUN stop python-api"* ]]
}

@test "services lifecycle can start and stop python api process" {
  run env BASE_DEMO_SERVICES_STATE_DIR="$TEST_TMPDIR/state" "$TEST_ROOT/bin/base-demo-services" --catalog "$TEST_CATALOG" start

  [ "$status" -eq 0 ]
  [[ "$output" == *"python-api started pid="* ]]

  sleep 0.5

  run env BASE_DEMO_SERVICES_STATE_DIR="$TEST_TMPDIR/state" "$TEST_ROOT/bin/base-demo-services" --catalog "$TEST_CATALOG" check

  [ "$status" -eq 0 ]
  [[ "$output" == *"python-api ok"* ]]

  run env BASE_DEMO_SERVICES_STATE_DIR="$TEST_TMPDIR/state" "$TEST_ROOT/bin/base-demo-services" --catalog "$TEST_CATALOG" stop

  [ "$status" -eq 0 ]
  [[ "$output" == *"python-api stopped"* ]]
}

#!/usr/bin/env bats

setup() {
  TEST_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd -P)"
}

@test "demo console React and Vite files are present" {
  [ -f "$TEST_ROOT/services/demo-console/package.json" ]
  [ -f "$TEST_ROOT/services/demo-console/package-lock.json" ]
  [ -f "$TEST_ROOT/services/demo-console/index.html" ]
  [ -f "$TEST_ROOT/services/demo-console/vite.config.js" ]
  [ -f "$TEST_ROOT/services/demo-console/src/main.jsx" ]
  [ -f "$TEST_ROOT/services/demo-console/src/App.jsx" ]
  [ -f "$TEST_ROOT/services/demo-console/src/App.css" ]
  [ -f "$TEST_ROOT/services/demo-console/scripts/prepare-catalog.mjs" ]
  [ -f "$TEST_ROOT/services/demo-console/scripts/validate-source.mjs" ]
  [ -f "$TEST_ROOT/services/demo-console/public/service-catalog.json" ]
  [ -x "$TEST_ROOT/services/demo-console/build.sh" ]
  [ -x "$TEST_ROOT/services/demo-console/test.sh" ]
  [ -x "$TEST_ROOT/services/demo-console/run.sh" ]

  grep -Fq '"react"' "$TEST_ROOT/services/demo-console/package.json"
  grep -Fq '"vite"' "$TEST_ROOT/services/demo-console/package.json"
}

@test "demo console build validation passes" {
  run "$TEST_ROOT/services/demo-console/build.sh"

  [ "$status" -eq 0 ]
  [[ "$output" == *"demo-console catalog contains"* ]]
}

@test "services status shows demo console UI" {
  run "$TEST_ROOT/bin/base-demo-services" status

  [ "$status" -eq 0 ]
  [[ "$output" == *"demo-console"* ]]
  [[ "$output" == *"ui"* ]]
  [[ "$output" == *"react-vite"* ]]
  [[ "$output" == *"8070"* ]]
}

@test "services lifecycle dry-run includes demo console command" {
  run env BASE_DEMO_SERVICES_DRY_RUN=1 "$TEST_ROOT/bin/base-demo-services" start

  [ "$status" -eq 0 ]
  [[ "$output" == *"DRY-RUN start demo-console"* ]]
  [[ "$output" == *"services/demo-console/run.sh"* ]]
}

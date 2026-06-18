#!/usr/bin/env bats

setup() {
  TEST_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd -P)"
}

@test "environment command and config files are present" {
  grep -Fq "environments: ./bin/base-demo-environments" "$TEST_ROOT/base_manifest.yaml"
  [ -x "$TEST_ROOT/bin/base-demo-environments" ]
  [ -f "$TEST_ROOT/environments/dev.json" ]
  [ -f "$TEST_ROOT/environments/staging.json" ]
  [ -f "$TEST_ROOT/environments/prod.json" ]
}

@test "environment command lists modeled environments" {
  run "$TEST_ROOT/bin/base-demo-environments" list

  [ "$status" -eq 0 ]
  [[ "$output" == *"dev"* ]]
  [[ "$output" == *"staging"* ]]
  [[ "$output" == *"prod"* ]]
}

@test "environment command shows operational boundary" {
  run "$TEST_ROOT/bin/base-demo-environments" show staging

  [ "$status" -eq 0 ]
  [[ "$output" == *"name=staging"* ]]
  [[ "$output" == *"operational=false"* ]]
  [[ "$output" == *"mode=modeled"* ]]
}

@test "environment command validates all modeled environments" {
  run "$TEST_ROOT/bin/base-demo-environments" validate --all

  [ "$status" -eq 0 ]
  [[ "$output" == *"dev ok"* ]]
  [[ "$output" == *"staging ok"* ]]
  [[ "$output" == *"prod ok"* ]]
}

@test "services command validates requested environment" {
  run "$TEST_ROOT/bin/base-demo-services" --env prod status

  [ "$status" -eq 0 ]
  [[ "$output" == *"environment=prod"* ]]
  [[ "$output" == *"mode=modeled"* ]]
}

@test "services command rejects unknown environments" {
  run "$TEST_ROOT/bin/base-demo-services" --env qa status

  [ "$status" -eq 2 ]
  [[ "$output" == *"ERROR: environment not found: qa"* ]]
}

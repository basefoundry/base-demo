#!/usr/bin/env bats

setup() {
  TEST_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd -P)"
}

@test "go api service files and catalog entry are present" {
  [ -f "$TEST_ROOT/services/go-api/go.mod" ]
  [ -f "$TEST_ROOT/services/go-api/main.go" ]
  [ -f "$TEST_ROOT/services/go-api/Dockerfile" ]
  grep -Fq '"name": "go-api"' "$TEST_ROOT/services/catalog.json"
  grep -Fq '"port": 8010' "$TEST_ROOT/services/catalog.json"
}

@test "go api dockerfile uses multi-stage build" {
  grep -Fq "FROM golang:" "$TEST_ROOT/services/go-api/Dockerfile"
  grep -Fq "FROM gcr.io/distroless" "$TEST_ROOT/services/go-api/Dockerfile"
}

@test "services status shows go api as dockerized service" {
  run "$TEST_ROOT/bin/base-demo-services" status

  [ "$status" -eq 0 ]
  [[ "$output" == *"go-api"* ]]
  [[ "$output" == *"service"* ]]
  [[ "$output" == *"docker"* ]]
  [[ "$output" == *"8010"* ]]
}

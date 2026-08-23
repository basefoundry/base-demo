#!/usr/bin/env bats

setup() {
  TEST_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd -P)"
  TEST_TMPDIR="$(mktemp -d "${TMPDIR:-/tmp}/base-demo-environments-test.XXXXXX")"
}

copy_environment_contract() {
  mkdir -p "$TEST_TMPDIR/services" "$TEST_TMPDIR/infra"
  cp "$TEST_ROOT/services/catalog.json" "$TEST_TMPDIR/services/catalog.json"
  cp "$TEST_ROOT/infra/compose.yaml" "$TEST_TMPDIR/infra/compose.yaml"
}

teardown() {
  rm -rf "$TEST_TMPDIR"
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
  [[ "$output" == *"services_selector=services --env <name>"* ]]
  [[ "$output" == *"base_health_marker=BASE_DEMO_ENV=baseline"* ]]
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

@test "environment command discovers additional JSON environments" {
  cp -R "$TEST_ROOT/environments" "$TEST_TMPDIR/environments"
  copy_environment_contract
  cat > "$TEST_TMPDIR/environments/local.json" <<'EOF'
{
  "name": "local",
  "mode": "modeled",
  "operational": false,
  "base_url": "http://127.0.0.1:18080",
  "logging": {
    "level": "debug",
    "format": "text"
  },
  "services": {},
  "infrastructure": {}
}
EOF

  run env BASE_PROJECT_ROOT="$TEST_TMPDIR" "$TEST_ROOT/bin/base-demo-environments" validate --all

  [ "$status" -eq 0 ]
  [[ "$output" == *"dev ok"* ]]
  [[ "$output" == *"local ok"* ]]
  [[ "$output" == *"prod ok"* ]]
  [[ "$output" == *"staging ok"* ]]
}

@test "environment validation reports actionable nested field paths" {
  mkdir -p "$TEST_TMPDIR/environments"
  copy_environment_contract
  cat > "$TEST_TMPDIR/environments/broken.json" <<'EOF'
{
  "name": "broken",
  "mode": "operational",
  "operational": false,
  "base_url": "ftp://user:secret@example.invalid",
  "logging": {
    "level": "verbose",
    "format": "xml",
    "sink": "remote"
  },
  "services": {
    "python-api": {
      "required": "yes",
      "enabled": true
    }
  },
  "infrastructure": {
    "postgres": {
      "enabled": "yes",
      "port": 70000,
      "database": "other"
    }
  },
  "region": "local"
}
EOF

  run env BASE_PROJECT_ROOT="$TEST_TMPDIR" "$TEST_ROOT/bin/base-demo-environments" validate broken

  [ "$status" -eq 1 ]
  [[ "$output" == *"operational environments must set operational to true"* ]]
  [[ "$output" == *"base_url must be an http or https URL without credentials"* ]]
  [[ "$output" == *"unsupported field: region"* ]]
  [[ "$output" == *"logging.level must be one of"* ]]
  [[ "$output" == *"logging.format must be one of"* ]]
  [[ "$output" == *"logging.sink is not supported"* ]]
  [[ "$output" == *"services.python-api.required must be a boolean"* ]]
  [[ "$output" == *"services.python-api.enabled is not supported"* ]]
  [[ "$output" == *"infrastructure.postgres.enabled must be a boolean"* ]]
  [[ "$output" == *"infrastructure.postgres.port must be an integer from 1 to 65535"* ]]
  [[ "$output" == *"infrastructure.postgres.database is not supported"* ]]
}

@test "environment validation rejects unknown catalog and Compose references" {
  mkdir -p "$TEST_TMPDIR/environments"
  copy_environment_contract
  cat > "$TEST_TMPDIR/environments/broken.json" <<'EOF'
{
  "name": "broken",
  "mode": "modeled",
  "operational": false,
  "base_url": "https://broken.example.invalid",
  "logging": {"level": "info", "format": "json"},
  "services": {
    "missing-api": {"required": false},
    "postgres": {"required": false}
  },
  "infrastructure": {
    "rabbitmq": {"enabled": false, "port": 5672},
    "go-api": {"enabled": false, "port": 8010}
  }
}
EOF

  run env BASE_PROJECT_ROOT="$TEST_TMPDIR" "$TEST_ROOT/bin/base-demo-environments" validate broken

  [ "$status" -eq 1 ]
  [[ "$output" == *"services.missing-api must reference a non-infrastructure catalog service"* ]]
  [[ "$output" == *"services.postgres must reference a non-infrastructure catalog service"* ]]
  [[ "$output" == *"infrastructure.rabbitmq must reference a catalog database/cache with a Compose service"* ]]
  [[ "$output" == *"infrastructure.go-api must reference a catalog database/cache with a Compose service"* ]]
}

@test "environment validation rejects infrastructure missing from Compose" {
  mkdir -p "$TEST_TMPDIR/environments" "$TEST_TMPDIR/services" "$TEST_TMPDIR/infra"
  cat > "$TEST_TMPDIR/environments/broken.json" <<'EOF'
{
  "name": "broken",
  "mode": "modeled",
  "operational": false,
  "base_url": "https://broken.example.invalid",
  "logging": {"level": "info", "format": "json"},
  "services": {},
  "infrastructure": {"postgres": {"enabled": false, "port": 5432}}
}
EOF
  cat > "$TEST_TMPDIR/services/catalog.json" <<'EOF'
{
  "services": [
    {
      "name": "postgres",
      "kind": "database",
      "compose_service": "postgres"
    }
  ]
}
EOF
  printf 'services:\n  redis:\n    image: redis:7-alpine\n' > "$TEST_TMPDIR/infra/compose.yaml"

  run env BASE_PROJECT_ROOT="$TEST_TMPDIR" "$TEST_ROOT/bin/base-demo-environments" validate broken

  [ "$status" -eq 1 ]
  [[ "$output" == *"infrastructure.postgres must reference a catalog database/cache with a Compose service"* ]]
}

@test "services command validates requested environment" {
  run "$TEST_ROOT/bin/base-demo-services" --env prod status

  [ "$status" -eq 0 ]
  [[ "$output" == *"environment=prod"* ]]
  [[ "$output" == *"mode=modeled"* ]]
  [[ "$output" == *"operational=false"* ]]
  [[ "$output" == *"project-baseline"* ]]
  [[ "$output" != *"postgres"* ]]
  [[ "$output" != *"python-api"* ]]
}

@test "services command rejects lifecycle operations for modeled environments" {
  local environment

  for environment in staging prod; do
    run env BASE_DEMO_SERVICES_DRY_RUN=1 "$TEST_ROOT/bin/base-demo-services" --env "$environment" start

    [ "$status" -eq 2 ]
    [[ "$output" == *"environment '$environment' is modeled and not operational"* ]]
    [[ "$output" == *"configuration examples, not deployable targets"* ]]
    [[ "$output" != *"DRY-RUN"* ]]
  done
}

@test "services command keeps dev operational and applies its selection" {
  run env BASE_DEMO_SERVICES_DRY_RUN=1 "$TEST_ROOT/bin/base-demo-services" --env dev start

  [ "$status" -eq 0 ]
  [[ "$output" == *"DRY-RUN docker compose"* ]]
  [[ "$output" == *"postgres"* ]]
  [[ "$output" == *"mysql"* ]]
  [[ "$output" == *"redis"* ]]
  [[ "$output" == *"go-api"* ]]
  [[ "$output" == *"DRY-RUN start python-api"* ]]
}

@test "services command excludes disabled infrastructure from read-only operations" {
  run env BASE_DEMO_SERVICES_DRY_RUN=1 "$TEST_ROOT/bin/base-demo-services" --env prod logs

  [ "$status" -eq 0 ]
  [[ "$output" != *"docker compose"* ]]
  [[ "$output" != *"postgres"* ]]
  [[ "$output" != *"mysql"* ]]
  [[ "$output" != *"redis"* ]]
}

@test "services command applies environment requiredness overrides" {
  mkdir -p "$TEST_TMPDIR/environments" "$TEST_TMPDIR/services"
  cat > "$TEST_TMPDIR/environments/custom.json" <<'EOF'
{
  "name": "custom",
  "mode": "operational",
  "operational": true,
  "base_url": "http://127.0.0.1",
  "logging": {"level": "debug", "format": "text"},
  "services": {"required-fixture": {"required": true}},
  "infrastructure": {}
}
EOF
  cat > "$TEST_TMPDIR/services/catalog.json" <<'EOF'
{
  "services": [
    {
      "name": "required-fixture",
      "kind": "service",
      "runtime": "test",
      "port": null,
      "health_url": null,
      "required": false,
      "check": {"type": "file", "path": "missing.required"},
      "logs": null
    }
  ]
}
EOF

  run env BASE_PROJECT_ROOT="$TEST_TMPDIR" "$TEST_ROOT/bin/base-demo-services" --env custom check

  [ "$status" -eq 1 ]
  [[ "$output" == *"required-fixture fail file:missing.required"* ]]
  [[ "$output" != *"skip optional"* ]]
}

@test "services command rejects structurally invalid environment configuration" {
  mkdir -p "$TEST_TMPDIR/environments" "$TEST_TMPDIR/services"
  cat > "$TEST_TMPDIR/environments/broken.json" <<'EOF'
{
  "name": "broken",
  "mode": "modeled",
  "operational": true,
  "base_url": "https://example.invalid",
  "logging": {},
  "services": {},
  "infrastructure": {}
}
EOF
  printf '{"services": []}\n' > "$TEST_TMPDIR/services/catalog.json"

  run env BASE_PROJECT_ROOT="$TEST_TMPDIR" "$TEST_ROOT/bin/base-demo-services" --env broken status

  [ "$status" -eq 2 ]
  [[ "$output" == *"environment broken is invalid"* ]]
  [[ "$output" == *"modeled environments must not be operational"* ]]
}

@test "services command rejects unknown environments" {
  run "$TEST_ROOT/bin/base-demo-services" --env qa status

  [ "$status" -eq 2 ]
  [[ "$output" == *"ERROR: environment not found: qa"* ]]
}

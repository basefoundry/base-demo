#!/usr/bin/env bash
set -euo pipefail

BASE_DEMO_PROJECT="${BASE_PROJECT:-base-demo}"
BASE_DEMO_ROOT="${BASE_PROJECT_ROOT:-}"
BASE_DEMO_BASECTL="${BASE_DEMO_BASECTL:-basectl}"
BASE_DEMO_NON_INTERACTIVE=0

demo_script_dir() {
  cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P
}

demo_project_root() {
  if [[ -n "$BASE_DEMO_ROOT" ]]; then
    cd -- "$BASE_DEMO_ROOT" && pwd -P
    return
  fi

  cd -- "$(demo_script_dir)/.." && pwd -P
}

BASE_DEMO_ROOT="$(demo_project_root)" || {
  printf 'ERROR: Unable to resolve base-demo project root.\n' >&2
  exit 1
}

if [[ -n "${MISE_TRUSTED_CONFIG_PATHS:-}" ]]; then
  export MISE_TRUSTED_CONFIG_PATHS="$BASE_DEMO_ROOT:$MISE_TRUSTED_CONFIG_PATHS"
else
  export MISE_TRUSTED_CONFIG_PATHS="$BASE_DEMO_ROOT"
fi

demo_workspace_root() {
  cd -- "$BASE_DEMO_ROOT/.." && pwd -P
}

BASE_DEMO_WORKSPACE="$(demo_workspace_root)" || {
  printf 'ERROR: Unable to resolve base-demo workspace root.\n' >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage:
  demo/demo.sh [--non-interactive] [-h|--help]

Run the base-demo interactive walkthrough.
EOF
}

parse_args() {
  while (($#)); do
    case "$1" in
      --non-interactive)
        BASE_DEMO_NON_INTERACTIVE=1
        ;;
      -h|--help|help)
        usage
        return 2
        ;;
      *)
        printf 'ERROR: Unknown demo option %q\n' "$1" >&2
        usage >&2
        return 1
        ;;
    esac
    shift
  done
}

pause() {
  if [[ "$BASE_DEMO_NON_INTERACTIVE" == "1" || ! -t 0 ]]; then
    return 0
  fi

  printf '\nPress Enter to continue...'
  read -r _
  printf '\n'
}

step() {
  printf '\n== Step %s: %s ==\n\n' "$1" "$2"
}

run_command() {
  printf '  $'
  printf ' %q' "$@"
  printf '\n'

  if ! "$@"; then
    printf '\nDemo step failed while running the command above.\n' >&2
    printf 'Run it manually from %s, fix the issue, and retry the demo.\n' "$BASE_DEMO_ROOT" >&2
    return 1
  fi
}

run_observed_command() {
  printf '  $'
  printf ' %q' "$@"
  printf '\n'

  if ! "$@"; then
    printf '\nDiagnostic command reported an issue; continuing the walkthrough.\n' >&2
  fi
}

capture_command() {
  local output

  printf '  $'
  printf ' %q' "$@"
  printf '\n\n'

  if ! output="$("$@" 2>&1)"; then
    printf '%s\n' "$output" >&2
    printf '\nDemo step failed while running the command above.\n' >&2
    return 1
  fi

  printf '%s\n' "$output"
}

require_contains() {
  local label="$1"
  local output="$2"
  local expected="$3"

  if [[ "$output" != *"$expected"* ]]; then
    printf 'ERROR: Expected %s output to contain %q.\n' "$label" "$expected" >&2
    return 1
  fi
}

intro() {
  printf '\nbase-demo Walkthrough\n\n'
  printf 'This demo shows a compact Base-managed representative environment.\n'
  printf 'Each step runs a real command or validates a real repo-owned contract.\n'
  pause
}

project_shape_step() {
  local repo_output

  step 1 "Project Shape"
  run_command test -f "$BASE_DEMO_ROOT/base_manifest.yaml"
  run_command test -f "$BASE_DEMO_ROOT/Brewfile"
  run_command test -f "$BASE_DEMO_ROOT/.mise.toml"
  run_command test -x "$BASE_DEMO_ROOT/bin/base-demo-python-info"
  run_command test -x "$BASE_DEMO_ROOT/bin/base-demo-services"
  run_command test -x "$BASE_DEMO_ROOT/bin/base-demo-environments"
  run_command test -f "$BASE_DEMO_ROOT/services/catalog.json"
  run_command test -f "$BASE_DEMO_ROOT/environments/dev.json"
  run_command test -f "$BASE_DEMO_ROOT/environments/staging.json"
  run_command test -f "$BASE_DEMO_ROOT/environments/prod.json"
  run_command test -x "$BASE_DEMO_ROOT/src/hello.sh"
  run_command test -x "$BASE_DEMO_ROOT/src/env.sh"
  run_command test -x "$BASE_DEMO_ROOT/src/manifest.sh"
  run_command test -x "$BASE_DEMO_ROOT/src/build-info.sh"
  run_command test -x "$BASE_DEMO_ROOT/tests/validate.sh"

  printf '\nChecking the repository baseline files separately from project health.\n'
  repo_output="$(capture_command "$BASE_DEMO_BASECTL" repo check .)"
  printf '%s\n' "$repo_output"
  require_contains "repo check" "$repo_output" "Repository baseline"
  pause
}

manifest_step() {
  step 2 "Manifest Contracts"
  run_command grep -n "name: base-demo" "$BASE_DEMO_ROOT/base_manifest.yaml"
  run_command grep -n "required_env:" "$BASE_DEMO_ROOT/base_manifest.yaml"
  run_command grep -n "required_ports:" "$BASE_DEMO_ROOT/base_manifest.yaml"
  run_command grep -n "requires_python:" "$BASE_DEMO_ROOT/base_manifest.yaml"
  run_command grep -n "mise: .mise.toml" "$BASE_DEMO_ROOT/base_manifest.yaml"
  run_command grep -n "hello: ./src/hello.sh" "$BASE_DEMO_ROOT/base_manifest.yaml"
  run_command grep -n "env: ./src/env.sh" "$BASE_DEMO_ROOT/base_manifest.yaml"
  run_command grep -n "manifest: ./src/manifest.sh" "$BASE_DEMO_ROOT/base_manifest.yaml"
  run_command grep -n "python-info: ./bin/base-demo-python-info" "$BASE_DEMO_ROOT/base_manifest.yaml"
  run_command grep -n "uv-info:" "$BASE_DEMO_ROOT/base_manifest.yaml"
  run_command grep -n "runner: uv" "$BASE_DEMO_ROOT/base_manifest.yaml"
  run_command grep -n "services: ./bin/base-demo-services" "$BASE_DEMO_ROOT/base_manifest.yaml"
  run_command grep -n "environments: ./bin/base-demo-environments" "$BASE_DEMO_ROOT/base_manifest.yaml"
  run_command grep -n "command: ./src/build-info.sh" "$BASE_DEMO_ROOT/base_manifest.yaml"
  run_command grep -n "working_dir: services/go-api" "$BASE_DEMO_ROOT/base_manifest.yaml"
  run_command grep -n "command: ./tests/validate.sh" "$BASE_DEMO_ROOT/base_manifest.yaml"
  run_command grep -n "script: ./demo/demo.sh" "$BASE_DEMO_ROOT/base_manifest.yaml"
  pause
}

discovery_step() {
  local output

  step 3 "Workspace Discovery"
  output="$(capture_command "$BASE_DEMO_BASECTL" projects list --workspace "$BASE_DEMO_WORKSPACE")"
  printf '%s\n' "$output"
  require_contains "projects list" "$output" "$BASE_DEMO_PROJECT"
  pause
}

setup_step() {
  local output

  step 4 "Setup Contract"
  printf 'Showing the setup reconciliation plan for manifest artifacts, Brewfile dependencies, mise tools, and the project virtualenv.\n'
  printf 'The representative manifest artifact is bats-core, managed as a Homebrew tool artifact by Base.\n'
  printf 'The walkthrough uses --dry-run so it is stable on machines where setup is already complete or local tool trust is pending.\n'
  printf 'For this process only, the project root is trusted for mise checks without changing persistent mise trust.\n'
  output="$(capture_command "$BASE_DEMO_BASECTL" setup "$BASE_DEMO_PROJECT" --manifest "$BASE_DEMO_ROOT/base_manifest.yaml" --dry-run --no-notify)"
  printf '%s\n' "$output"
  if [[ "$output" != *"bats-core"* ]]; then
    printf 'Artifact reconciliation may be deferred until the project virtualenv is healthy; the declared artifact is bats-core.\n'
  fi
  pause
}

diagnostics_step() {
  step 5 "Project Diagnostics"
  printf 'The manifest declares BASE_DEMO_ENV as a required_env health check.\n'
  printf 'The green path has BASE_DEMO_ENV=baseline from activation or CI.\n'
  printf 'Before activation, check and doctor can report a useful diagnostic instead.\n'
  printf 'The walkthrough displays those diagnostic commands without making them the success gate.\n\n'
  run_observed_command "$BASE_DEMO_BASECTL" check "$BASE_DEMO_PROJECT" --manifest "$BASE_DEMO_ROOT/base_manifest.yaml"
  run_observed_command "$BASE_DEMO_BASECTL" doctor "$BASE_DEMO_PROJECT" --manifest "$BASE_DEMO_ROOT/base_manifest.yaml"
  pause
}

activation_step() {
  local check_output doctor_output

  step 6 "Project Activation Source"
  # shellcheck source=/dev/null
  source "$BASE_DEMO_ROOT/.base/activate.sh" || return 1
  printf 'BASE_DEMO_ENV=%s\n' "${BASE_DEMO_ENV:-unset}"
  printf 'BASE_DEMO_ACTIVATED=%s\n' "${BASE_DEMO_ACTIVATED:-unset}"
  printf 'BASE_DEMO_PROJECT_KIND=%s\n' "${BASE_DEMO_PROJECT_KIND:-unset}"
  require_contains "activation" "${BASE_DEMO_ENV:-}" "baseline"
  require_contains "activation" "${BASE_DEMO_ACTIVATED:-}" "true"
  require_contains "activation" "${BASE_DEMO_PROJECT_KIND:-}" "reference-demo"

  printf '\nRunning the post-activation green path through check and doctor.\n'
  check_output="$(capture_command "$BASE_DEMO_BASECTL" check "$BASE_DEMO_PROJECT" --manifest "$BASE_DEMO_ROOT/base_manifest.yaml")"
  printf '%s\n' "$check_output"

  doctor_output="$(capture_command "$BASE_DEMO_BASECTL" doctor "$BASE_DEMO_PROJECT" --manifest "$BASE_DEMO_ROOT/base_manifest.yaml")"
  printf '%s\n' "$doctor_output"
  pause
}

command_discovery_step() {
  local output

  step 7 "Declared Commands"
  output="$(capture_command "$BASE_DEMO_BASECTL" run "$BASE_DEMO_PROJECT" --workspace "$BASE_DEMO_WORKSPACE" --list)"
  printf '%s\n' "$output"
  require_contains "run command list" "$output" "hello"
  require_contains "run command list" "$output" "env"
  require_contains "run command list" "$output" "manifest"
  require_contains "run command list" "$output" "python-info"
  require_contains "run command list" "$output" "uv-info"
  require_contains "run command list" "$output" "services"
  require_contains "run command list" "$output" "environments"
  pause
}

run_step() {
  local output

  step 8 "Declared Command Execution"
  output="$(capture_command "$BASE_DEMO_BASECTL" run "$BASE_DEMO_PROJECT" --workspace "$BASE_DEMO_WORKSPACE" hello)"
  printf '%s\n' "$output"
  require_contains "run command" "$output" "hello from base-demo"
  pause
}

inspection_step() {
  local env_output manifest_output python_output uv_output services_output environments_output

  step 9 "Inspection Commands"
  printf 'Inspecting activation and manifest environment values.\n'
  env_output="$(capture_command "$BASE_DEMO_BASECTL" run "$BASE_DEMO_PROJECT" --workspace "$BASE_DEMO_WORKSPACE" env)"
  printf '%s\n' "$env_output"
  require_contains "env command" "$env_output" "BASE_PROJECT=base-demo"
  require_contains "env command" "$env_output" "BASE_DEMO_PROJECT_KIND=reference-demo"

  printf '\nReading the manifest summary command.\n'
  manifest_output="$(capture_command "$BASE_DEMO_BASECTL" run "$BASE_DEMO_PROJECT" --workspace "$BASE_DEMO_WORKSPACE" manifest)"
  printf '%s\n' "$manifest_output"
  require_contains "manifest command" "$manifest_output" "base-demo manifest"
  require_contains "manifest command" "$manifest_output" "commands:"

  printf '\nConfirming the Base-managed Python command runs inside the project environment.\n'
  python_output="$(capture_command "$BASE_DEMO_BASECTL" run "$BASE_DEMO_PROJECT" --workspace "$BASE_DEMO_WORKSPACE" python-info)"
  printf '%s\n' "$python_output"
  require_contains "python command" "$python_output" "base-demo python cli"
  require_contains "python command" "$python_output" "BASE_PROJECT=base-demo"

  printf '\nConfirming a command-level uv runner can be selected without making uv the project manager.\n'
  uv_output="$(capture_command "$BASE_DEMO_BASECTL" run "$BASE_DEMO_PROJECT" --workspace "$BASE_DEMO_WORKSPACE" uv-info)"
  printf '%s\n' "$uv_output"
  require_contains "uv command" "$uv_output" "base-demo uv runner"

  printf '\nViewing the representative service catalog and health states.\n'
  services_output="$(capture_command "$BASE_DEMO_BASECTL" run "$BASE_DEMO_PROJECT" --workspace "$BASE_DEMO_WORKSPACE" services -- status)"
  printf '%s\n' "$services_output"
  require_contains "services command" "$services_output" "project-baseline"
  require_contains "services command" "$services_output" "healthy"

  printf '\nListing modeled environments and deployment boundaries.\n'
  environments_output="$(capture_command "$BASE_DEMO_BASECTL" run "$BASE_DEMO_PROJECT" --workspace "$BASE_DEMO_WORKSPACE" environments -- list)"
  printf '%s\n' "$environments_output"
  require_contains "environments command" "$environments_output" "dev"
  require_contains "environments command" "$environments_output" "staging"
  require_contains "environments command" "$environments_output" "prod"
  require_contains "environments command" "$environments_output" "modeled"
  pause
}

representative_environment_step() {
  local check_output start_output validate_output

  step 10 "Representative Environment"
  printf 'Checking representative service health.\n'
  check_output="$(capture_command "$BASE_DEMO_BASECTL" run "$BASE_DEMO_PROJECT" --workspace "$BASE_DEMO_WORKSPACE" services -- check)"
  printf '%s\n' "$check_output"
  require_contains "services check" "$check_output" "project-baseline ok"
  require_contains "services check" "$check_output" "c-service"
  require_contains "services check" "$check_output" "cpp-service"
  require_contains "services check" "$check_output" "demo-console"

  printf '\nDry-running service startup without launching dependencies.\n'
  start_output="$(capture_command env BASE_DEMO_SERVICES_DRY_RUN=1 "$BASE_DEMO_BASECTL" run "$BASE_DEMO_PROJECT" --workspace "$BASE_DEMO_WORKSPACE" services -- start)"
  printf '%s\n' "$start_output"
  require_contains "services dry-run start" "$start_output" "DRY-RUN docker compose"
  require_contains "services dry-run start" "$start_output" "go-api"
  require_contains "services dry-run start" "$start_output" "demo-console"

  printf '\nValidating every modeled environment file.\n'
  validate_output="$(capture_command "$BASE_DEMO_BASECTL" run "$BASE_DEMO_PROJECT" --workspace "$BASE_DEMO_WORKSPACE" environments -- validate --all)"
  printf '%s\n' "$validate_output"
  require_contains "environment validation" "$validate_output" "dev"
  require_contains "environment validation" "$validate_output" "staging"
  require_contains "environment validation" "$validate_output" "prod"
  pause
}

test_step() {
  local output

  step 11 "Test Contract"
  output="$(capture_command "$BASE_DEMO_BASECTL" test "$BASE_DEMO_PROJECT" --workspace "$BASE_DEMO_WORKSPACE")"
  printf '%s\n' "$output"
  require_contains "test command" "$output" "Repository baseline is present."
  pause
}

build_step() {
  local output

  step 12 "Build Targets"
  output="$(capture_command "$BASE_DEMO_BASECTL" build "$BASE_DEMO_PROJECT" --workspace "$BASE_DEMO_WORKSPACE" --list)"
  printf '%s\n' "$output"
  require_contains "build list" "$output" "info"
  require_contains "build list" "$output" "go-api"
  require_contains "build list" "$output" "python-api"
  require_contains "build list" "$output" "java-gradle-api"
  require_contains "build list" "$output" "java-maven-api"
  require_contains "build list" "$output" "c-service"
  require_contains "build list" "$output" "cpp-service"
  require_contains "build list" "$output" "demo-console"

  output="$(capture_command "$BASE_DEMO_BASECTL" build "$BASE_DEMO_PROJECT" --workspace "$BASE_DEMO_WORKSPACE")"
  printf '%s\n' "$output"
  require_contains "build output" "$output" "project=base-demo"

  output="$(capture_command "$BASE_DEMO_BASECTL" build "$BASE_DEMO_PROJECT" python-api --workspace "$BASE_DEMO_WORKSPACE")"
  printf '%s\n' "$output"
  require_contains "python-api build output" "$output" "python-api"
  pause
}

demo_step() {
  local output

  step 13 "Demo Contract"
  output="$(capture_command "$BASE_DEMO_BASECTL" demo "$BASE_DEMO_PROJECT" --workspace "$BASE_DEMO_WORKSPACE" --dry-run -- --non-interactive)"
  printf '%s\n' "$output"
  require_contains "demo command" "$output" "Would run demo"
  pause
}

closing_summary() {
  printf '\nWalkthrough Summary\n\n'
  printf 'Manifest fields exercised: activate, health.required_env, commands, test, build, demo, brewfile, and mise.\n'
  printf 'Next steps: read docs/representative-environment.md for the environment model.\n'
  printf 'For a deeper application shape, compare this reference repo with banyanlabs.\n'
  printf '\nbase-demo walkthrough complete.\n'
}

main() {
  parse_args "$@" || {
    local status=$?
    [[ "$status" -eq 2 ]] && return 0
    return "$status"
  }

  cd -- "$BASE_DEMO_ROOT" || return 1
  intro
  project_shape_step
  manifest_step
  discovery_step
  setup_step
  diagnostics_step
  activation_step
  command_discovery_step
  run_step
  inspection_step
  representative_environment_step
  test_step
  build_step
  demo_step
  closing_summary
}

main "$@"

#!/usr/bin/env bash

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

capture_command() {
  local output

  printf '  $'
  printf ' %q' "$@"
  printf '\n'

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
  printf 'This demo shows the smallest useful Base-managed project shape.\n'
  printf 'Each step runs a real command or validates a real file in this repo.\n'
  pause
}

project_shape_step() {
  step 1 "Project Shape"
  run_command test -f "$BASE_DEMO_ROOT/base_manifest.yaml"
  run_command test -f "$BASE_DEMO_ROOT/Brewfile"
  run_command test -x "$BASE_DEMO_ROOT/bin/base-demo-python-info"
  run_command test -x "$BASE_DEMO_ROOT/src/hello.sh"
  run_command test -x "$BASE_DEMO_ROOT/src/env.sh"
  run_command test -x "$BASE_DEMO_ROOT/src/manifest.sh"
  run_command test -x "$BASE_DEMO_ROOT/tests/validate.sh"
  pause
}

manifest_step() {
  step 2 "Manifest Contracts"
  run_command grep -n "name: base-demo" "$BASE_DEMO_ROOT/base_manifest.yaml"
  run_command grep -n "hello: ./src/hello.sh" "$BASE_DEMO_ROOT/base_manifest.yaml"
  run_command grep -n "env: ./src/env.sh" "$BASE_DEMO_ROOT/base_manifest.yaml"
  run_command grep -n "manifest: ./src/manifest.sh" "$BASE_DEMO_ROOT/base_manifest.yaml"
  run_command grep -n "python-info: ./bin/base-demo-python-info" "$BASE_DEMO_ROOT/base_manifest.yaml"
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

diagnostics_step() {
  step 4 "Project Diagnostics"
  printf 'The manifest declares BASE_DEMO_ENV as a required_env health check.\n'
  printf 'basectl check reports it as missing until basectl activate sources .base/activate.sh.\n\n'
  run_command "$BASE_DEMO_BASECTL" check "$BASE_DEMO_PROJECT"
  run_command "$BASE_DEMO_BASECTL" doctor "$BASE_DEMO_PROJECT"
  pause
}

activation_step() {
  step 5 "Project Activation Source"
  # shellcheck source=/dev/null
  source "$BASE_DEMO_ROOT/.base/activate.sh" || return 1
  printf 'BASE_DEMO_ENV=%s\n' "${BASE_DEMO_ENV:-unset}"
  printf 'BASE_DEMO_ACTIVATED=%s\n' "${BASE_DEMO_ACTIVATED:-unset}"
  printf 'BASE_DEMO_PROJECT_KIND=%s\n' "${BASE_DEMO_PROJECT_KIND:-unset}"
  require_contains "activation" "${BASE_DEMO_ENV:-}" "baseline"
  require_contains "activation" "${BASE_DEMO_ACTIVATED:-}" "true"
  require_contains "activation" "${BASE_DEMO_PROJECT_KIND:-}" "reference-demo"
  pause
}

command_discovery_step() {
  local output

  step 6 "Declared Commands"
  output="$(capture_command "$BASE_DEMO_BASECTL" run "$BASE_DEMO_PROJECT" --workspace "$BASE_DEMO_WORKSPACE" --list)"
  printf '%s\n' "$output"
  require_contains "run command list" "$output" "hello"
  require_contains "run command list" "$output" "env"
  require_contains "run command list" "$output" "manifest"
  require_contains "run command list" "$output" "python-info"
  pause
}

run_step() {
  local output

  step 7 "Declared Command Execution"
  output="$(capture_command "$BASE_DEMO_BASECTL" run "$BASE_DEMO_PROJECT" --workspace "$BASE_DEMO_WORKSPACE" hello)"
  printf '%s\n' "$output"
  require_contains "run command" "$output" "hello from base-demo"
  pause
}

inspection_step() {
  local env_output manifest_output python_output

  step 8 "Inspection Commands"
  env_output="$(capture_command "$BASE_DEMO_BASECTL" run "$BASE_DEMO_PROJECT" --workspace "$BASE_DEMO_WORKSPACE" env)"
  printf '%s\n' "$env_output"
  require_contains "env command" "$env_output" "BASE_PROJECT=base-demo"
  require_contains "env command" "$env_output" "BASE_DEMO_PROJECT_KIND=reference-demo"

  manifest_output="$(capture_command "$BASE_DEMO_BASECTL" run "$BASE_DEMO_PROJECT" --workspace "$BASE_DEMO_WORKSPACE" manifest)"
  printf '%s\n' "$manifest_output"
  require_contains "manifest command" "$manifest_output" "base-demo manifest"
  require_contains "manifest command" "$manifest_output" "commands:"

  python_output="$(capture_command "$BASE_DEMO_BASECTL" run "$BASE_DEMO_PROJECT" --workspace "$BASE_DEMO_WORKSPACE" python-info)"
  printf '%s\n' "$python_output"
  require_contains "python command" "$python_output" "base-demo python cli"
  require_contains "python command" "$python_output" "BASE_PROJECT=base-demo"
  pause
}

test_step() {
  local output

  step 9 "Test Contract"
  output="$(capture_command "$BASE_DEMO_BASECTL" test "$BASE_DEMO_PROJECT" --workspace "$BASE_DEMO_WORKSPACE")"
  printf '%s\n' "$output"
  require_contains "test command" "$output" "Repository baseline is present."
  pause
}

build_step() {
  local output

  step 10 "Build Targets"
  output="$(capture_command "$BASE_DEMO_BASECTL" build "$BASE_DEMO_PROJECT" --workspace "$BASE_DEMO_WORKSPACE" --list)"
  printf '%s\n' "$output"
  require_contains "build list" "$output" "info"

  output="$(capture_command "$BASE_DEMO_BASECTL" build "$BASE_DEMO_PROJECT" --workspace "$BASE_DEMO_WORKSPACE")"
  printf '%s\n' "$output"
  require_contains "build output" "$output" "project=base-demo"
  pause
}

demo_step() {
  local output

  step 11 "Demo Contract"
  output="$(capture_command "$BASE_DEMO_BASECTL" demo "$BASE_DEMO_PROJECT" --workspace "$BASE_DEMO_WORKSPACE" --dry-run -- --non-interactive)"
  printf '%s\n' "$output"
  require_contains "demo command" "$output" "Would run demo"
  pause
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
  diagnostics_step
  activation_step
  command_discovery_step
  run_step
  inspection_step
  test_step
  build_step
  demo_step
  printf '\nbase-demo walkthrough complete.\n'
}

main "$@"

#!/usr/bin/env bats

setup() {
  TEST_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd -P)"
  TEST_TMPDIR="$(mktemp -d "${TMPDIR:-/tmp}/base-demo-install-test.XXXXXX")"
  TEST_FAKE_BIN="$TEST_TMPDIR/bin"
  TEST_INSTALLER="$TEST_TMPDIR/base-install.sh"
  TEST_MARKER="$TEST_TMPDIR/installer-executed"
  TEST_GIT_LOG="$TEST_TMPDIR/git.log"
  TEST_BASE_COMMIT="26b9af5dee16efcb47e652513ce734b3ae9bc920"
  TEST_PROJECT_COMMIT="b74521c85d410cb67e497560976e0d95fc53fd41"

  mkdir -p "$TEST_FAKE_BIN"
  write_fake_curl
  write_fake_git
  write_test_installer
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

write_fake_curl() {
  cat > "$TEST_FAKE_BIN/curl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

output=""
while (($#)); do
  case "$1" in
    -o)
      output="$2"
      shift 2
      ;;
    -*)
      shift
      ;;
    *)
      shift
      ;;
  esac
done

if [[ -z "$output" ]]; then
  printf 'fake curl expected -o <path>\n' >&2
  exit 1
fi

cp "${BASE_DEMO_TEST_INSTALLER:?}" "$output"
EOF
  chmod +x "$TEST_FAKE_BIN/curl"
}

write_fake_git() {
  cat > "$TEST_FAKE_BIN/git" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

printf '%s\n' "$*" >> "${BASE_DEMO_TEST_GIT_LOG:?}"

if [[ "${1:-}" == "-C" ]]; then
  checkout_dir="${2:?}"
  operation="${3:-}"
  if [[ "$operation" == "status" || ("$operation" == "rev-parse" && "${4:-}" == "HEAD") ]]; then
    case "$checkout_dir" in
      */base)
        if [[ "$operation" == "status" ]]; then
          printf '%s\n' "${BASE_DEMO_TEST_BASE_STATUS:-}"
        else
          printf '%s\n' "${BASE_DEMO_TEST_BASE_COMMIT:?}"
        fi
        ;;
      *)
        if [[ "$operation" == "status" ]]; then
          printf '%s\n' "${BASE_DEMO_TEST_PROJECT_STATUS:-}"
        else
          printf '%s\n' "${BASE_DEMO_TEST_PROJECT_COMMIT:?}"
        fi
      ;;
    esac
  fi
  exit 0
fi

if [[ "${1:-}" == "clone" ]]; then
  project_dir=""
  for argument in "$@"; do
    project_dir="$argument"
  done
  mkdir -p "$project_dir/.git"
  printf 'name: base-demo\n' > "$project_dir/base_manifest.yaml"
  exit 0
fi

printf 'unexpected fake git args: %s\n' "$*" >&2
exit 1
EOF
  chmod +x "$TEST_FAKE_BIN/git"
}

write_test_installer() {
  cat > "$TEST_INSTALLER" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

base_dir=""
while (($#)); do
  case "$1" in
    --dir)
      base_dir="$2"
      shift 2
      ;;
    --no-profile)
      shift
      ;;
    *)
      shift
      ;;
  esac
done

mkdir -p "$base_dir/.git" "$base_dir/bin"
cat > "$base_dir/bin/basectl" <<'BASECTL'
#!/usr/bin/env bash
printf 'basectl %s\n' "$*"
BASECTL
chmod +x "$base_dir/bin/basectl"
printf 'executed\n' > "${BASE_DEMO_TEST_MARKER:?}"
EOF
  chmod +x "$TEST_INSTALLER"
}

run_installer() {
  local checksum="${1:-}"
  shift || true
  env \
    PATH="$TEST_FAKE_BIN:$PATH" \
    BASE_DEMO_TEST_INSTALLER="$TEST_INSTALLER" \
    BASE_DEMO_TEST_MARKER="$TEST_MARKER" \
    BASE_DEMO_TEST_GIT_LOG="$TEST_GIT_LOG" \
    BASE_DEMO_TEST_BASE_COMMIT="$TEST_BASE_COMMIT" \
    BASE_DEMO_TEST_PROJECT_COMMIT="$TEST_PROJECT_COMMIT" \
    WORKSPACE_DIR="$TEST_TMPDIR/work" \
    BASE_INSTALL_URL="https://example.invalid/base-install.sh" \
    BASE_INSTALL_SHA256="$checksum" \
    BASE_RELEASE_COMMIT="$TEST_BASE_COMMIT" \
    PROJECT_RELEASE_COMMIT="$TEST_PROJECT_COMMIT" \
    RUN_UPDATE_PROFILE=false \
    "$TEST_ROOT/install.sh" "$@"
}

installer_sha256() {
  shasum -a 256 "$TEST_INSTALLER" | awk '{print $1}'
}

@test "install.sh aborts before executing installer when checksum mismatches" {
  run run_installer "0000000000000000000000000000000000000000000000000000000000000000"

  [ "$status" -ne 0 ]
  [[ "$output" == *"checksum mismatch"* ]]
  [ ! -f "$TEST_MARKER" ]
}

@test "install.sh aborts in release mode when checksum is not configured" {
  run run_installer ""

  [ "$status" -ne 0 ]
  [[ "$output" == *"checksum is required in release mode"* ]]
  [ ! -f "$TEST_MARKER" ]
}

@test "install.sh verifies matching checksum before executing installer" {
  run run_installer "$(installer_sha256)"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Verified Base installer SHA-256"* ]]
  [[ "$output" != *"checksum verification skipped"* ]]
  [ -f "$TEST_MARKER" ]
}

@test "install.sh pins the Base and project revisions on a fresh release install" {
  run run_installer "$(installer_sha256)"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Installing pinned Base release 'v1.8.0'"* ]]
  [[ "$output" == *"Cloning pinned base-demo release 'v0.1.0'"* ]]
  [[ "$output" == *"Verified pinned Base commit $TEST_BASE_COMMIT"* ]]
  [[ "$output" == *"Verified pinned base-demo commit $TEST_PROJECT_COMMIT"* ]]
  grep -Fq -- "clone --depth 1 --branch v0.1.0 https://github.com/basefoundry/base-demo.git" "$TEST_GIT_LOG"
  [ -f "$TEST_MARKER" ]
}

@test "install.sh refuses to move an existing checkout that is not at the release pin" {
  mkdir -p "$TEST_TMPDIR/work/base/.git" "$TEST_TMPDIR/work/base-demo/.git"
  printf '%s\n' "unexpected" > "$TEST_TMPDIR/work/base/.git/placeholder"
  run env \
    PATH="$TEST_FAKE_BIN:$PATH" \
    BASE_DEMO_TEST_INSTALLER="$TEST_INSTALLER" \
    BASE_DEMO_TEST_MARKER="$TEST_MARKER" \
    BASE_DEMO_TEST_GIT_LOG="$TEST_GIT_LOG" \
    BASE_DEMO_TEST_BASE_COMMIT="unexpected-base" \
    BASE_DEMO_TEST_PROJECT_COMMIT="$TEST_PROJECT_COMMIT" \
    WORKSPACE_DIR="$TEST_TMPDIR/work" \
    BASE_INSTALL_URL="https://example.invalid/base-install.sh" \
    BASE_INSTALL_SHA256="$(installer_sha256)" \
    BASE_RELEASE_COMMIT="$TEST_BASE_COMMIT" \
    PROJECT_RELEASE_COMMIT="$TEST_PROJECT_COMMIT" \
    RUN_UPDATE_PROFILE=false \
    "$TEST_ROOT/install.sh"

  [ "$status" -ne 0 ]
  [[ "$output" == *"expected pinned release commit '$TEST_BASE_COMMIT'"* ]]
  run grep -Fq -- "pull" "$TEST_GIT_LOG"
  [ "$status" -ne 0 ]
  [ ! -f "$TEST_MARKER" ]
}

@test "install.sh refuses to use a dirty existing checkout in release mode" {
  mkdir -p "$TEST_TMPDIR/work/base/.git" "$TEST_TMPDIR/work/base-demo/.git"
  run env \
    PATH="$TEST_FAKE_BIN:$PATH" \
    BASE_DEMO_TEST_INSTALLER="$TEST_INSTALLER" \
    BASE_DEMO_TEST_MARKER="$TEST_MARKER" \
    BASE_DEMO_TEST_GIT_LOG="$TEST_GIT_LOG" \
    BASE_DEMO_TEST_BASE_COMMIT="$TEST_BASE_COMMIT" \
    BASE_DEMO_TEST_BASE_STATUS=" M install.sh" \
    BASE_DEMO_TEST_PROJECT_COMMIT="$TEST_PROJECT_COMMIT" \
    WORKSPACE_DIR="$TEST_TMPDIR/work" \
    BASE_INSTALL_URL="https://example.invalid/base-install.sh" \
    BASE_INSTALL_SHA256="$(installer_sha256)" \
    BASE_RELEASE_COMMIT="$TEST_BASE_COMMIT" \
    PROJECT_RELEASE_COMMIT="$TEST_PROJECT_COMMIT" \
    RUN_UPDATE_PROFILE=false \
    "$TEST_ROOT/install.sh"

  [ "$status" -ne 0 ]
  [[ "$output" == *"has local changes"* ]]
  [ ! -f "$TEST_MARKER" ]
}

@test "install.sh --dev reuses sibling checkouts without pulling or switching revisions" {
  mkdir -p "$TEST_TMPDIR/work/base/.git" "$TEST_TMPDIR/work/base-demo/.git" "$TEST_TMPDIR/work/base/bin"
  cat > "$TEST_TMPDIR/work/base/bin/basectl" <<'EOF'
#!/usr/bin/env bash
printf 'basectl %s\n' "$*"
EOF
  chmod +x "$TEST_TMPDIR/work/base/bin/basectl"
  printf 'name: base-demo\n' > "$TEST_TMPDIR/work/base-demo/base_manifest.yaml"

  run env \
    PATH="$TEST_FAKE_BIN:$PATH" \
    BASE_DEMO_TEST_INSTALLER="$TEST_INSTALLER" \
    BASE_DEMO_TEST_MARKER="$TEST_MARKER" \
    BASE_DEMO_TEST_GIT_LOG="$TEST_GIT_LOG" \
    BASE_DEMO_TEST_BASE_COMMIT="feature-base" \
    BASE_DEMO_TEST_PROJECT_COMMIT="feature-demo" \
    WORKSPACE_DIR="$TEST_TMPDIR/work" \
    BASE_INSTALL_SHA256="" \
    RUN_UPDATE_PROFILE=false \
    "$TEST_ROOT/install.sh" --dev

  [ "$status" -eq 0 ]
  [[ "$output" == *"Mode: developer"* ]]
  [[ "$output" == *"without pulling or switching revisions"* ]]
  run grep -Fq -- "pull" "$TEST_GIT_LOG"
  [ "$status" -ne 0 ]
  run grep -Fq -- "clone" "$TEST_GIT_LOG"
  [ "$status" -ne 0 ]
  [ ! -f "$TEST_MARKER" ]
}

@test "BASE_DEMO_DEV_MODE enables the same safe local-checkout behavior" {
  mkdir -p "$TEST_TMPDIR/work/base/.git" "$TEST_TMPDIR/work/base-demo/.git" "$TEST_TMPDIR/work/base/bin"
  cat > "$TEST_TMPDIR/work/base/bin/basectl" <<'EOF'
#!/usr/bin/env bash
printf 'basectl %s\n' "$*"
EOF
  chmod +x "$TEST_TMPDIR/work/base/bin/basectl"
  printf 'name: base-demo\n' > "$TEST_TMPDIR/work/base-demo/base_manifest.yaml"

  run env \
    PATH="$TEST_FAKE_BIN:$PATH" \
    BASE_DEMO_TEST_INSTALLER="$TEST_INSTALLER" \
    BASE_DEMO_TEST_MARKER="$TEST_MARKER" \
    BASE_DEMO_TEST_GIT_LOG="$TEST_GIT_LOG" \
    BASE_DEMO_TEST_BASE_COMMIT="feature-base" \
    BASE_DEMO_TEST_PROJECT_COMMIT="feature-demo" \
    WORKSPACE_DIR="$TEST_TMPDIR/work" \
    BASE_DEMO_DEV_MODE=1 \
    BASE_INSTALL_SHA256="" \
    RUN_UPDATE_PROFILE=false \
    "$TEST_ROOT/install.sh"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Mode: developer"* ]]
  run grep -Fq -- "pull" "$TEST_GIT_LOG"
  [ "$status" -ne 0 ]
  run grep -Fq -- "clone" "$TEST_GIT_LOG"
  [ "$status" -ne 0 ]
}

#!/usr/bin/env bats

setup() {
  TEST_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd -P)"
  TEST_TMPDIR="$(mktemp -d "${TMPDIR:-/tmp}/base-demo-install-test.XXXXXX")"
  TEST_FAKE_BIN="$TEST_TMPDIR/bin"
  TEST_INSTALLER="$TEST_TMPDIR/base-install.sh"
  TEST_MARKER="$TEST_TMPDIR/installer-executed"

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

if [[ "${1:-}" == "-C" ]]; then
  exit 0
fi

if [[ "${1:-}" == "clone" ]]; then
  project_dir="${3:?}"
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
  env \
    PATH="$TEST_FAKE_BIN:$PATH" \
    BASE_DEMO_TEST_INSTALLER="$TEST_INSTALLER" \
    BASE_DEMO_TEST_MARKER="$TEST_MARKER" \
    WORKSPACE_DIR="$TEST_TMPDIR/work" \
    BASE_INSTALL_URL="https://example.invalid/base-install.sh" \
    BASE_INSTALL_SHA256="${1:-}" \
    RUN_UPDATE_PROFILE=false \
    "$TEST_ROOT/install.sh"
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

@test "install.sh warns but continues when checksum is not configured" {
  run run_installer ""

  [ "$status" -eq 0 ]
  [[ "$output" == *"WARNING: Base installer checksum verification skipped"* ]]
  [ -f "$TEST_MARKER" ]
}

@test "install.sh verifies matching checksum before executing installer" {
  run run_installer "$(installer_sha256)"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Verified Base installer SHA-256"* ]]
  [[ "$output" != *"checksum verification skipped"* ]]
  [ -f "$TEST_MARKER" ]
}

#!/usr/bin/env bash

# Explicit error handling is used instead of set -e to keep failure paths
# clear and predictable. See Base STANDARDS.md section 2.

# Project-owned values.
PROJECT_NAME="${PROJECT_NAME:-base-demo}"
PROJECT_REPO_URL="${PROJECT_REPO_URL:-https://github.com/basefoundry/base-demo.git}"
BASE_REPO_URL="${BASE_REPO_URL:-https://github.com/basefoundry/base.git}"
WORKSPACE_DIR="${WORKSPACE_DIR:-$HOME/work}"
BASE_DIR="${BASE_DIR:-$WORKSPACE_DIR/base}"
PROJECT_DIR="${PROJECT_DIR:-$WORKSPACE_DIR/$PROJECT_NAME}"
BASE_RELEASE_REF="${BASE_RELEASE_REF:-v1.8.0}"
BASE_RELEASE_COMMIT="${BASE_RELEASE_COMMIT:-26b9af5dee16efcb47e652513ce734b3ae9bc920}"
BASE_INSTALL_URL="${BASE_INSTALL_URL:-https://raw.githubusercontent.com/basefoundry/base/${BASE_RELEASE_REF}/install.sh}"
# The empty-value form is intentional: an explicit empty checksum must not
# silently restore the release checksum and bypass the release-mode guard.
BASE_INSTALL_SHA256="${BASE_INSTALL_SHA256-492dd06eee86223c780f011b545cdef8e11964489c8a2d54c9da426f55ed9980}"
PROJECT_RELEASE_REF="${PROJECT_RELEASE_REF:-v0.1.0}"
PROJECT_RELEASE_COMMIT="${PROJECT_RELEASE_COMMIT:-b8ac2ae490e4965b8131195a11377fd0bd787daf}"
BASE_DEMO_DEV_MODE="${BASE_DEMO_DEV_MODE:-false}"
RUN_UPDATE_PROFILE="${RUN_UPDATE_PROFILE:-true}"

INSTALLER_TMP=""
DEV_MODE=false

log() {
    printf '%s\n' "$*"
}

die() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

usage() {
    cat <<'EOF'
Usage:
  install.sh [--dev] [-h|--help]

Install or validate the pinned base-demo release workspace. Existing
developer checkouts are never switched or reset. Use --dev, or set
BASE_DEMO_DEV_MODE=1, to reuse local sibling checkouts as-is.

Environment:
  BASE_DIR, PROJECT_DIR, WORKSPACE_DIR
  BASE_REPO_URL, BASE_RELEASE_REF, BASE_RELEASE_COMMIT
  BASE_INSTALL_URL, BASE_INSTALL_SHA256
  PROJECT_REPO_URL, PROJECT_RELEASE_REF, PROJECT_RELEASE_COMMIT
  RUN_UPDATE_PROFILE
EOF
}

run() {
    printf '+'
    printf ' %q' "$@"
    printf '\n'
    "$@"
}

verify_base_installer_checksum() {
    local installer_file="$1"
    local checksum
    local actual_sha256

    if [[ -z "$BASE_INSTALL_SHA256" ]]; then
        if [[ "$DEV_MODE" == true ]]; then
            log "WARNING: Base installer checksum verification skipped in developer mode; set BASE_INSTALL_SHA256 to verify the override."
            return 0
        fi
        die "Base installer checksum is required in release mode; set BASE_INSTALL_SHA256 only with an explicit verified value or use --dev."
    fi

    require_command shasum
    checksum="$(shasum -a 256 "$installer_file")" || die "Failed to compute Base installer checksum."
    actual_sha256="${checksum%% *}"
    if [[ "$actual_sha256" != "$BASE_INSTALL_SHA256" ]]; then
        die "Base installer checksum mismatch (expected $BASE_INSTALL_SHA256, got $actual_sha256)."
    fi

    log "Verified Base installer SHA-256 $actual_sha256."
}

cleanup() {
    if [[ -n "$INSTALLER_TMP" && -f "$INSTALLER_TMP" ]]; then
        rm -f "$INSTALLER_TMP"
    fi
}
trap cleanup EXIT

require_command() {
    command -v "$1" >/dev/null 2>&1 || die "Required command '$1' was not found."
}

ensure_workspace() {
    run mkdir -p "$WORKSPACE_DIR" || die "Failed to create workspace directory '$WORKSPACE_DIR'."
}

is_git_checkout() {
    [[ -e "$1/.git" ]]
}

verify_release_checkout() {
    local label="$1"
    local checkout_dir="$2"
    local expected_commit="$3"
    local checkout_status
    local actual_commit

    checkout_status="$(git -C "$checkout_dir" status --porcelain --untracked-files=no 2>/dev/null)" || {
        die "$label checkout at '$checkout_dir' could not be inspected. Release mode will not modify an existing checkout; use --dev for a contributor workspace."
    }
    if [[ -n "$checkout_status" ]]; then
        die "$label checkout at '$checkout_dir' has local changes. Release mode will not modify it; use --dev for a contributor workspace."
    fi

    actual_commit="$(git -C "$checkout_dir" rev-parse HEAD 2>/dev/null)" || {
        die "$label checkout at '$checkout_dir' could not be inspected. Release mode will not modify an existing checkout; use --dev for a contributor workspace."
    }
    if [[ "$actual_commit" != "$expected_commit" ]]; then
        die "$label checkout at '$actual_commit'; expected pinned release commit '$expected_commit'. Release mode will not switch an existing checkout; use --dev for a contributor workspace."
    fi
    log "Verified pinned $label commit $actual_commit."
}

install_or_update_base() {
    require_command git

    if is_git_checkout "$BASE_DIR"; then
        if [[ "$DEV_MODE" == true ]]; then
            log "Developer mode: reusing Base checkout at '$BASE_DIR' without pulling or switching revisions."
        else
            log "Release mode: reusing Base checkout at '$BASE_DIR'."
            verify_release_checkout "Base" "$BASE_DIR" "$BASE_RELEASE_COMMIT"
        fi
        return 0
    fi

    if [[ -e "$BASE_DIR" ]]; then
        die "Base path '$BASE_DIR' exists but is not a Git checkout."
    fi

    require_command curl
    INSTALLER_TMP="$(mktemp "${TMPDIR:-/tmp}/base-install.XXXXXX")" || die "Failed to create installer temp file."
    if [[ "$DEV_MODE" == true ]]; then
        log "WARNING: Developer mode is cloning Base from the configured moving/default source."
    else
        log "Installing pinned Base release '$BASE_RELEASE_REF' into '$BASE_DIR'."
    fi
    run curl -fsSL -o "$INSTALLER_TMP" "$BASE_INSTALL_URL" || die "Failed to download Base installer."
    verify_base_installer_checksum "$INSTALLER_TMP" || die "Base installer checksum verification failed."
    if [[ "$DEV_MODE" == true ]]; then
        run bash "$INSTALLER_TMP" --dir "$BASE_DIR" --repo-url "$BASE_REPO_URL" --no-profile || die "Failed to install Base into '$BASE_DIR'."
    else
        run bash "$INSTALLER_TMP" --dir "$BASE_DIR" --repo-url "$BASE_REPO_URL" --branch "$BASE_RELEASE_REF" --no-profile || die "Failed to install Base into '$BASE_DIR'."
        is_git_checkout "$BASE_DIR" || die "Pinned Base installer did not create a Git checkout at '$BASE_DIR'."
        verify_release_checkout "Base" "$BASE_DIR" "$BASE_RELEASE_COMMIT"
    fi
}

clone_or_update_project() {
    require_command git

    if is_git_checkout "$PROJECT_DIR"; then
        if [[ "$DEV_MODE" == true ]]; then
            log "Developer mode: reusing $PROJECT_NAME checkout at '$PROJECT_DIR' without pulling or switching revisions."
        else
            log "Release mode: reusing $PROJECT_NAME checkout at '$PROJECT_DIR'."
            verify_release_checkout "$PROJECT_NAME" "$PROJECT_DIR" "$PROJECT_RELEASE_COMMIT"
        fi
        return 0
    fi

    if [[ -e "$PROJECT_DIR" ]]; then
        die "Project path '$PROJECT_DIR' exists but is not a Git checkout."
    fi

    if [[ "$DEV_MODE" == true ]]; then
        log "WARNING: Developer mode is cloning $PROJECT_NAME from the repository's moving/default branch."
        run git clone "$PROJECT_REPO_URL" "$PROJECT_DIR" || die "Failed to clone $PROJECT_NAME into '$PROJECT_DIR'."
    else
        log "Cloning pinned $PROJECT_NAME release '$PROJECT_RELEASE_REF' into '$PROJECT_DIR'."
        run git clone --depth 1 --branch "$PROJECT_RELEASE_REF" "$PROJECT_REPO_URL" "$PROJECT_DIR" || die "Failed to clone $PROJECT_NAME release."
        is_git_checkout "$PROJECT_DIR" || die "Pinned $PROJECT_NAME clone did not create a Git checkout at '$PROJECT_DIR'."
        verify_release_checkout "$PROJECT_NAME" "$PROJECT_DIR" "$PROJECT_RELEASE_COMMIT"
    fi
}

run_project_setup() {
    local manifest="$PROJECT_DIR/base_manifest.yaml"

    [[ -f "$manifest" ]] || die "Project manifest was not found at '$manifest'."
    [[ -x "$BASE_DIR/bin/basectl" ]] || die "Base CLI was not found at '$BASE_DIR/bin/basectl'."

    if ! run "$BASE_DIR/bin/basectl" setup --manifest "$PROJECT_DIR/base_manifest.yaml" "$PROJECT_NAME"; then
        log "Project setup failed. Running Base doctor for more detail."
        run "$BASE_DIR/bin/basectl" doctor "$PROJECT_NAME" || true
        die "Project setup failed."
    fi
}

maybe_update_profile() {
    case "$RUN_UPDATE_PROFILE" in
        true|1|yes)
            run "$BASE_DIR/bin/basectl" update-profile || die "Failed to update shell profiles."
            ;;
        false|0|no)
            log "Skipping shell profile update."
            ;;
        *)
            die "RUN_UPDATE_PROFILE must be true or false."
            ;;
    esac
}

parse_dev_mode_env() {
    case "$BASE_DEMO_DEV_MODE" in
        true|1|yes)
            DEV_MODE=true
            ;;
        false|0|no)
            ;;
        *)
            die "BASE_DEMO_DEV_MODE must be true or false."
            ;;
    esac
}

parse_args() {
    while (($# > 0)); do
        case "$1" in
            --dev)
                DEV_MODE=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                usage >&2
                die "Unknown option '$1'."
                ;;
        esac
    done
}

main() {
    parse_dev_mode_env
    parse_args "$@"

    log "Installing $PROJECT_NAME workspace."
    log "Workspace: $WORKSPACE_DIR"
    if [[ "$DEV_MODE" == true ]]; then
        log "Mode: developer (local checkouts are preserved; moving-source overrides are explicit)."
    else
        log "Mode: release (Base $BASE_RELEASE_REF at $BASE_RELEASE_COMMIT; $PROJECT_NAME $PROJECT_RELEASE_REF at $PROJECT_RELEASE_COMMIT)."
    fi

    ensure_workspace || die "Workspace preparation failed."
    install_or_update_base || die "Base installation failed."
    clone_or_update_project || die "$PROJECT_NAME checkout failed."
    run_project_setup || die "$PROJECT_NAME setup failed."
    maybe_update_profile || die "Shell profile update failed."

    log "$PROJECT_NAME setup is complete."
    log "Try: cd '$PROJECT_DIR' && ./tests/validate.sh"
}

main "$@"

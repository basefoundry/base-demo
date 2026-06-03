#!/usr/bin/env bash
set -euo pipefail

manifest="${BASE_PROJECT_MANIFEST:-base_manifest.yaml}"

printf 'base-demo manifest\n'
printf 'path=%s\n' "$manifest"
grep -nE '^(schema_version|brewfile|activate:|commands:|test:|demo:|artifacts:)' "$manifest"

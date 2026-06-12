#!/usr/bin/env bash

manifest="${BASE_PROJECT_MANIFEST:-base_manifest.yaml}"

printf 'base-demo manifest\n'
printf 'path=%s\n' "$manifest"
grep -nE '^(schema_version|project:|  name:|brewfile|activate:|commands:|test:|demo:|artifacts:)' "$manifest"

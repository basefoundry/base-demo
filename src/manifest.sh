#!/usr/bin/env bash

manifest="${BASE_PROJECT_MANIFEST:-base_manifest.yaml}"

printf 'base-demo manifest\n'
printf 'path=%s\n' "$manifest"
grep -nE '^(schema_version|project:|  name:|brewfile|health:|mise:|activate:|commands:|build:|test:|demo:|artifacts:)' "$manifest"

#!/usr/bin/env bash

version_file="${BASE_PROJECT_ROOT:-.}/VERSION"

printf 'project=%s\n' "${BASE_PROJECT:-base-demo}"
printf 'version=%s\n' "$(cat "$version_file" 2>/dev/null || echo 'unknown')"
printf 'build-target=info\n'

#!/usr/bin/env bash
set -euo pipefail

missing=()
for tool in go javac; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    missing+=("$tool")
  fi
done

if ((${#missing[@]} > 0)); then
  printf 'Full validation requires Go and Java toolchains; missing: %s.\n' "${missing[*]}" >&2
  exit 1
fi

go_version="$(go version 2>&1)" || {
  printf 'Full validation could not execute go version.\n' >&2
  exit 1
}
javac_version="$(javac -version 2>&1)" || {
  printf 'Full validation could not execute javac -version.\n' >&2
  exit 1
}

printf 'Full validation toolchains: %s; %s\n' "$go_version" "$javac_version"

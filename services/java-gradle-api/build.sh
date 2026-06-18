#!/usr/bin/env bash
set -euo pipefail

service_dir() {
  cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P
}

cd "$(service_dir)"
if command -v gradle >/dev/null 2>&1; then
  gradle --no-daemon clean check
else
  printf 'Skipping java-gradle-api Gradle build because gradle is not available.\n'
fi
./test.sh

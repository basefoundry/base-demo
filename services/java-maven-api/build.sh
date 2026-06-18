#!/usr/bin/env bash
set -euo pipefail

service_dir() {
  cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P
}

cd "$(service_dir)"
if command -v mvn >/dev/null 2>&1; then
  mvn -q -DskipTests package
else
  printf 'Skipping java-maven-api Maven build because mvn is not available.\n'
fi
./test.sh

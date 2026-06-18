#!/usr/bin/env bash
set -euo pipefail

service_dir() {
  cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P
}

cd "$(service_dir)"
rm -rf build/run-classes
mkdir -p build/run-classes
javac -d build/run-classes src/main/java/com/codeforester/basedemo/javagradle/JavaGradleApi.java
exec java -cp build/run-classes com.codeforester.basedemo.javagradle.JavaGradleApi

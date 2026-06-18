#!/usr/bin/env bash
set -euo pipefail

service_dir() {
  cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P
}

cd "$(service_dir)"
classes_dir="build/test-classes-$$"
rm -rf "$classes_dir"
mkdir -p "$classes_dir"
trap 'rm -rf "$classes_dir"' EXIT
javac -d "$classes_dir" \
  src/main/java/com/codeforester/basedemo/javagradle/JavaGradleApi.java \
  src/test/java/com/codeforester/basedemo/javagradle/JavaGradleApiTest.java
java -cp "$classes_dir" com.codeforester.basedemo.javagradle.JavaGradleApiTest

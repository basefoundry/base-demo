#!/usr/bin/env bash

service_dir() {
  cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P
}

repo_root() {
  cd -- "$(service_dir)/../.." && pwd -P
}

cd "$(repo_root)" || exit 1
python3 tests/python_api_test.py

#!/usr/bin/env bash

service_dir() {
  cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P
}

cd "$(service_dir)" || exit 1
python3 -m py_compile server.py

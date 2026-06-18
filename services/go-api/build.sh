#!/usr/bin/env bash

service_dir() {
  cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P
}

cd "$(service_dir)" || exit 1
CGO_ENABLED=0 go build ./...

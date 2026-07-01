#!/usr/bin/env bash

print_var() {
  local name="$1"
  printf '%s=%s\n' "$name" "${!name:-unset}"
}

print_var BASE_PROJECT
print_var BASE_PROJECT_ROOT
print_var BASE_PROJECT_MANIFEST
print_var BASE_PROJECT_VENV_DIR
print_var BASE_OS
print_var BASE_PLATFORM
print_var BASE_DEMO_ENV
print_var BASE_DEMO_ACTIVATED
print_var BASE_DEMO_PROJECT_KIND

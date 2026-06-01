#!/usr/bin/env bash
set -euo pipefail

printf 'hello from base-demo\n'
printf 'BASE_PROJECT=%s\n' "${BASE_PROJECT:-unset}"
printf 'BASE_DEMO_ENV=%s\n' "${BASE_DEMO_ENV:-unset}"

set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

project := "base-demo"

default:
    just --list

check:
    basectl check {{project}}

ci-check:
    basectl check --ci {{project}} --format json

test:
    basectl test {{project}}

build:
    basectl build {{project}}

demo:
    basectl demo {{project}}

services:
    basectl run {{project}} services -- status

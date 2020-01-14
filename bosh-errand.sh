#!/bin/bash
# vim: set ft=sh

set -eu

args=("${BOSH_ERRAND}")
args+=(${BOSH_FLAGS:-})
bosh -n run-errand "${args[@]}"

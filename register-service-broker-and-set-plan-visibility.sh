#!/bin/bash

set -eux

here=$(dirname $0)
pushd $(dirname "$0")
  ./register-service-broker.sh
  ./set-plan-visibily.sh "$@"
popd

#!/bin/bash
# vim: set ft=sh

set -e

if [ -z "$STATE_FILE" ]; then
  echo "must specify \$STATE_FILE" >&2
  exit 1
fi

SCRIPTPATH=$( cd $(dirname $0) ; pwd -P )

cat terraform-state/$STATE_FILE | $SCRIPTPATH/terraform-state-to-yaml.py > terraform-yaml/state.yml

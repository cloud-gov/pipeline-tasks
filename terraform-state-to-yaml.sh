#!/bin/bash
# vim: set ft=sh

set -e

if [ -z "$STATE_FILE" ]; then
  echo "must specify \$STATE_FILE" >&2
  exit 1
fi

SCRIPTPATH=$( cd $(dirname $0) ; pwd -P )

# Install required gems if not installed
if [ -z $(gem list -i yaml) ]; then
  gem install yaml --no-ri --no-rdoc 2>&1 > /dev/null
fi
if [ -z $(gem list -i json) ]; then
  gem install json --no-ri --no-rdoc 2>&1 > /dev/null
fi

cat terraform-state/$STATE_FILE | $SCRIPTPATH/terraform-state-to-yaml.rb > terraform-yaml/state.yml

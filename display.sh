#!/bin/bash
# vim: set ft=sh

set -e -x

#
# A little environment validation
#
if [ -z "$FILE" ]; then
  echo "must specify \$FILE" >&2
  exit 1
fi

#
# Display the contents of a file
#
cat "$FILE"

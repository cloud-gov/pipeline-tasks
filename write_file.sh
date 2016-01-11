#!/bin/bash
# vim: set ft=sh

set -e

#
# A little environment validation
#
if [ -z "$CONTENT" ]; then
  echo "must specify \$CONTENT" >&2
  exit 1
fi
if [ -z "$FILE_NAME" ]; then
  echo "must specify \$FILE_NAME" >&2
  exit 1
fi

#
# Render content into a file
#
cat <<EOF > "$FILE_NAME"
$CONTENT
EOF

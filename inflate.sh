#!/bin/bash
# vim: set ft=sh

set -e -x

#
# A little environment validation
#
if [ -z "$INPUT_DIR" ]; then
  echo "must specify \$INPUT_DIR" >&2
  exit 1
fi

#
# Temporary file for storing compressed directory
#
NOW=`date +"%m-%d-%Y-%H-%M-%S"`
TEMP_FILE="inflate-$NOW.tar.gz"

#
# Inflate a given directory into a new one with symbolic links dereferenced
#
tar -C "$INPUT_DIR" -czhf "$TEMP_FILE" .
tar -xzf "$TEMP_FILE"

rm -f "$TEMP_FILE"

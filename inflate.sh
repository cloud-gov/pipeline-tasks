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

touch "hello.txt"

#
# Temporary file for storing compressed directory
#
TEMP_FILE=inflate-`date +"%m-%d-%Y-%T"`.tar.gz

#
# Inflate a given directory into a new one with symbolic links dereferenced
#
tar -czhf "$TEMP_FILE" "$INPUT_DIR"
tar -xzf "$TEMP_FILE"
rm -f "$TEMP_FILE"

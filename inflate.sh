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
OUTPUT_DIR="extract"

#
# Inflate a given directory into a new one with symbolic links dereferenced
#
tar -czhf "$TEMP_FILE" "$INPUT_DIR"

mkdir -p "$OUTPUT_DIR"
tar -xzf "$TEMP_FILE" -C "$OUTPUT_DIR"
mv "$OUTPUT_DIR"/* .

rm -Rf "$OUTPUT_DIR"
rm -f "$TEMP_FILE"

#!/bin/bash
# vim: set ft=sh

set -e -x

#
# A little environment validation
#
if [ -z "$OUTPUT_FILE" ]; then
  echo "must specify \$OUTPUT_FILE" >&2
  exit 1
fi
if [ -z "$SOURCE_FILE" ]; then
  echo "must specify \$SOURCE_FILE" >&2
  exit 1
fi
if [ -z "$MERGE_FILES" ]; then
  echo "must specify \$MERGE_FILES" >&2
  exit 1
fi

#
# Merge a source file with one or more merge files into an output file
#
spiff-merge-and-save "$OUTPUT_FILE" "$SOURCE_FILE" $MERGE_FILES

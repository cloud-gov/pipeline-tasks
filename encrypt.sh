#!/bin/bash
# vim: set ft=sh

set -e -x

#
# A little environment validation
#
if [ -z "$INPUT_FILE" ]; then
  echo "must specify \$INPUT_FILE" >&2
  exit 1
fi
if [ -z "$OUTPUT_FILE" ]; then
  echo "must specify \$OUTPUT_FILE" >&2
  exit 1
fi
if [ -z "$PASSPHRASE" ]; then
  echo "must specify \$PASSPHRASE" >&2
  exit 1
fi

#
# Encrypt input file into output file given passphrase
#
openssl enc -aes-256-cbc -a -in "$INPUT_FILE" -out "$OUTPUT_FILE" -pass "pass:$PASSPHRASE" 2>&1 >/dev/null

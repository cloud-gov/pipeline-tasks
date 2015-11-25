#!/bin/bash
# vim: set ft=sh

set -e -x

#
# A little environment validation
#
if [ -z "$RESOURCE" ]; then
  echo "must specify \$RESOURCE" >&2
  exit 1
fi

#
# Decrypt input file into output file given passphrase
#
ls -al $RESOURCE

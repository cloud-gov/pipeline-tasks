#!/bin/bash
# vim: set ft=sh

set -e

#
# A little environment validation
#
if [ -z "$1" ]; then
  echo "must specify release url" >&2
  exit 1
fi
if [ -z "$BOSH_TARGET" ]; then
  echo "must specify \$BOSH_TARGET" >&2
  exit 1
fi
if [ -z "$BOSH_USERNAME" ]; then
  echo "must specify \$BOSH_USERNAME" >&2
  exit 1
fi
if [ -z "$BOSH_PASSWORD" ]; then
  echo "must specify \$BOSH_PASSWORD" >&2
  exit 1
fi

#
# Target BOSH
#
bosh -n target $BOSH_TARGET
bosh -n login $BOSH_USERNAME $BOSH_PASSWORD
bosh -n upload release `cat $1` --skip-if-exists
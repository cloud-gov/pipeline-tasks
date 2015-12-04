#!/bin/bash
# vim: set ft=sh

set -e

#
# A little environment validation
#
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
if [ -z "$RELEASE_URL_FILE" ]; then
  echo "must specify \$RELEASE_URL_FILE" >&2
  exit 1
fi
if [ -z "$RELEASE_NAME" ]; then
  echo "must specify \$RELEASE_NAME" >&2
  exit 1
fi
if [ -z "$RELEASE_VERSION_FILE" ]; then
  echo "must specify \$RELEASE_VERSION_FILE" >&2
  exit 1
fi

#
# Target BOSH
#
echo "Uploading $RELEASE_NAME @ `cat $RELEASE_VERSION_FILE`: `cat $RELEASE_URL_FILE`"
bosh -n target $BOSH_TARGET
bosh -n login $BOSH_USERNAME $BOSH_PASSWORD
bosh -n upload release `cat $RELEASE_URL_FILE` --name $RELEASE_NAME --version `cat $RELEASE_VERSION_FILE`
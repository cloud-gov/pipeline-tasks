#!/bin/bash

set -e

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

bosh --ca-cert certificate/boshCA.crt -n target $BOSH_TARGET

bosh login $BOSH_USERNAME $BOSH_PASSWORD

for r in release/*.tgz; do
	bosh upload release $r
done

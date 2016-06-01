#!/bin/bash

set -e

if [ -z "$BOSH_CERT" ]; then
  echo "must specify \$BOSH_CERT" >&2
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

bosh --ca-cert $BOSH_CERT -n target $BOSH_TARGET

bosh login <<EOF 1>/dev/null
$BOSH_USERNAME
$BOSH_PASSWORD
EOF

for r in release/*.tgz; do
	bosh upload release $r
done
